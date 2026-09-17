# provider.tf: 클라우드 공급자(AWS/Azure/GCP 등), 버전, 리전 설정
# variables.tf: 파일에서 정의된 변수를 사용하여 클라우드 공급자 설정을 구성합니다.
# terraform.tfvars: 변수 파일에서 정의된 값을 사용하여 클라우드 공급자 설정을 구성합니다.
# local.tf: 로컬 변수
# data.tf: 기존 리소스 정의(조회)
# outputs.tf: 출력 값 및 모듈로 기존 리소스 연결
# main.tf: 리소스 정의 및 모듈 호출

# ########################################################################################################
# 1. 테라폼 실행 환경 설정 블록
# ########################################################################################################
terraform {
  # 1. 사용할 프로바이더 정의 블록
  required_providers {
    aws = {
      source  = "hashicorp/aws" # 프로바이더라이브러리 다운로드 경로
      version = "~> 6.0"        # 사용할 버전 정의
    }
  }

  #   required_providers {
  #     google = {
  #       source  = "hashicorp/google"
  #       version = "~> 6.0"
  #     }
  #   }

  # 2. S3 원격 백엔드 설정 (필수 인자 작성 필요), 상태값 파일을 공유해야하며, 누가 작업했는지 기록을 남기기 위해서 S3 원격 백엔드를 사용합니다.
  #   backend "s3" {
  #     bucket         = "std04-terraform-state-bucket-20260917"
  #     key            = "terraform/network/terraform.tfstate"
  #     region         = "ap-northeast-2"
  #     dynamodb_table = "std04-lock-table" # 동시 실행 방지(선택 사항이나 권장)
  #     encrypt        = true
  #   }
}

# 3. 실제 리소스를 프로비저닝할 AWS Provider 설정 (별도 블록)
provider "aws" {
  region = "ap-northeast-2"
  default_tags {
    tags = {
      Owner = "std04"
      Class = "bipa17"
    }
  }
}

# ###########################################################################
# 2. 상태 파일 저장을 위한 버킷 및 버전 활성화
# ###########################################################################

# 2-1. S3 버킷 생성
resource "aws_s3_bucket" "terraform_state" {
  bucket = "std04-terraform-state-bucket-20260917"

  # 실습 종료 후 삭제를 원활하게 하려면 force_destroy를 true로 설정 (버킷 내 객체가 있어도 삭제 허용)
  force_destroy = true

  # 운영 환경에서는 실수 삭제 방지를 위해 아래 설정을 고려할 수 있습니다.
  # lifecycle {
  #   prevent_destroy = true
  # }
}

# 2-2. S3 버전 관리 활성화 (과거 tfstate 파일 보존 및 복구용)
resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# # 2-3. S3 기본 암호화 설정 (AES256)
# resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_encryption" {
#   bucket = aws_s3_bucket.terraform_state.id

#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }

# # 2-4. 퍼블릭 액세스 전체 차단 (tfstate 보안 필수 설정)
# resource "aws_s3_bucket_public_access_block" "terraform_state_public_access_block" {
#   bucket = aws_s3_bucket.terraform_state.id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# ###########################################################################
# 3. 상태 락(State Lock)을 위한 DynamoDB 테이블 생성
# ###########################################################################
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "std04-lock-table"
  billing_mode = "PAY_PER_REQUEST" # 온디맨드 요금제 (실습/소규모 프로젝트에 경제적)
  hash_key     = "LockID"          # 테라폼 상태 락을 위해 키 이름은 반드시 'LockID' (문자열)여야 함

  attribute {
    name = "LockID"
    type = "S"
  }
}
