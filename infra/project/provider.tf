terraform {
  # 1. 사용할 프로바이더 정의 블록
  required_providers {
    aws = {
      source  = "hashicorp/aws" # 프로바이더라이브러리 다운로드 경로
      version = "~> 6.0"        # 사용할 버전 정의
    }
  }

  #   backend "s3" {
  #     bucket         = "std04-terraform-state-bucket-20260917"
  #     key            = "terraform/cicd/terraform.tfstate"
  #     region         = "ap-northeast-2"
  #     dynamodb_table = "std04-lock-table" # 동시 실행 방지(선택 사항이나 권장)
  #     encrypt        = true

  #   }
}

provider "aws" {
  region = "ap-northeast-2"
  default_tags {
    tags = {
      Owner = "std04"
      Class = "bipa17"
    }
  }
}
