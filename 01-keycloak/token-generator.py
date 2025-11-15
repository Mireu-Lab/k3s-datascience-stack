#!/usr/bin/env python3
"""
Keycloak JWT Token Generator for ResearchOps Projects
프로젝트별 Spark, HDFS, PostgreSQL 접근 토큰 생성
"""

import requests
import json
import argparse
from datetime import datetime, timedelta

class KeycloakTokenManager:
    def __init__(self, keycloak_url, realm="researchops"):
        self.keycloak_url = keycloak_url.rstrip('/')
        self.realm = realm
        self.token_endpoint = f"{self.keycloak_url}/realms/{self.realm}/protocol/openid-connect/token"
        self.admin_token_endpoint = f"{self.keycloak_url}/realms/master/protocol/openid-connect/token"
    
    def get_admin_token(self, username, password):
        """관리자 토큰 획득"""
        data = {
            "username": username,
            "password": password,
            "grant_type": "password",
            "client_id": "admin-cli"
        }
        
        response = requests.post(self.admin_token_endpoint, data=data)
        response.raise_for_status()
        return response.json()["access_token"]
    
    def get_service_token(self, client_id, client_secret, scope=None):
        """서비스 계정 토큰 획득 (Spark, HDFS, PostgreSQL)"""
        data = {
            "grant_type": "client_credentials",
            "client_id": client_id,
            "client_secret": client_secret
        }
        
        if scope:
            data["scope"] = scope
        
        response = requests.post(self.token_endpoint, data=data)
        response.raise_for_status()
        return response.json()
    
    def get_user_token(self, username, password, client_id="jupyterhub", client_secret=None):
        """사용자 토큰 획득 (JupyterHub, Grafana)"""
        data = {
            "username": username,
            "password": password,
            "grant_type": "password",
            "client_id": client_id
        }
        
        if client_secret:
            data["client_secret"] = client_secret
        
        response = requests.post(self.token_endpoint, data=data)
        response.raise_for_status()
        return response.json()
    
    def refresh_token(self, refresh_token, client_id, client_secret=None):
        """토큰 갱신"""
        data = {
            "grant_type": "refresh_token",
            "refresh_token": refresh_token,
            "client_id": client_id
        }
        
        if client_secret:
            data["client_secret"] = client_secret
        
        response = requests.post(self.token_endpoint, data=data)
        response.raise_for_status()
        return response.json()
    
    def introspect_token(self, token, client_id, client_secret):
        """토큰 검증 및 정보 조회"""
        introspect_endpoint = f"{self.keycloak_url}/realms/{self.realm}/protocol/openid-connect/token/introspect"
        
        data = {
            "token": token,
            "client_id": client_id,
            "client_secret": client_secret
        }
        
        response = requests.post(introspect_endpoint, data=data)
        response.raise_for_status()
        return response.json()
    
    def create_project_tokens(self, project_name, user_email, client_secrets):
        """프로젝트별 모든 서비스 토큰 생성"""
        tokens = {
            "project": project_name,
            "user": user_email,
            "created_at": datetime.utcnow().isoformat(),
            "expires_in": 7200,
            "services": {}
        }
        
        # Spark 토큰
        if "spark" in client_secrets:
            spark_token = self.get_service_token(
                "spark",
                client_secrets["spark"],
                scope=f"project_access resource_access"
            )
            tokens["services"]["spark"] = {
                "access_token": spark_token["access_token"],
                "token_type": spark_token["token_type"],
                "expires_in": spark_token["expires_in"]
            }
        
        # HDFS 토큰
        if "hdfs" in client_secrets:
            hdfs_token = self.get_service_token(
                "hdfs",
                client_secrets["hdfs"],
                scope=f"project_access resource_access"
            )
            tokens["services"]["hdfs"] = {
                "access_token": hdfs_token["access_token"],
                "token_type": hdfs_token["token_type"],
                "expires_in": hdfs_token["expires_in"]
            }
        
        # PostgreSQL 토큰
        if "postgresql" in client_secrets:
            pg_token = self.get_service_token(
                "postgresql",
                client_secrets["postgresql"],
                scope=f"project_access resource_access"
            )
            tokens["services"]["postgresql"] = {
                "access_token": pg_token["access_token"],
                "token_type": pg_token["token_type"],
                "expires_in": pg_token["expires_in"]
            }
        
        return tokens
    
    def save_tokens(self, tokens, output_file):
        """토큰을 파일로 저장"""
        with open(output_file, 'w') as f:
            json.dump(tokens, f, indent=2)
        print(f"Tokens saved to {output_file}")
    
    def load_tokens(self, input_file):
        """파일에서 토큰 로드"""
        with open(input_file, 'r') as f:
            return json.load(f)


def main():
    parser = argparse.ArgumentParser(
        description="Keycloak JWT Token Generator for ResearchOps"
    )
    parser.add_argument(
        "--keycloak-url",
        default="https://keycloak.mireu.xyz",
        help="Keycloak server URL"
    )
    parser.add_argument(
        "--realm",
        default="researchops",
        help="Keycloak realm"
    )
    parser.add_argument(
        "--project",
        required=True,
        help="Project name"
    )
    parser.add_argument(
        "--user-email",
        required=True,
        help="User email"
    )
    parser.add_argument(
        "--spark-secret",
        help="Spark client secret"
    )
    parser.add_argument(
        "--hdfs-secret",
        help="HDFS client secret"
    )
    parser.add_argument(
        "--pg-secret",
        help="PostgreSQL client secret"
    )
    parser.add_argument(
        "--output",
        default="project-tokens.json",
        help="Output file for tokens"
    )
    
    args = parser.parse_args()
    
    # Initialize token manager
    manager = KeycloakTokenManager(args.keycloak_url, args.realm)
    
    # Prepare client secrets
    client_secrets = {}
    if args.spark_secret:
        client_secrets["spark"] = args.spark_secret
    if args.hdfs_secret:
        client_secrets["hdfs"] = args.hdfs_secret
    if args.pg_secret:
        client_secrets["postgresql"] = args.pg_secret
    
    # Generate tokens
    print(f"Generating tokens for project: {args.project}")
    print(f"User: {args.user_email}")
    
    try:
        tokens = manager.create_project_tokens(
            args.project,
            args.user_email,
            client_secrets
        )
        
        # Save tokens
        manager.save_tokens(tokens, args.output)
        
        print("\nTokens generated successfully!")
        print(f"\nProject: {tokens['project']}")
        print(f"User: {tokens['user']}")
        print(f"Services: {', '.join(tokens['services'].keys())}")
        print(f"Expires in: {tokens['expires_in']} seconds")
        
    except Exception as e:
        print(f"Error: {e}")
        return 1
    
    return 0


if __name__ == "__main__":
    exit(main())
