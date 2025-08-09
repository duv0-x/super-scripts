#!/usr/bin/env bash
# aws_inventory.sh
# Inventories common AWS resources across all enabled regions + global services.
# Output: JSONL (one JSON object per line) to stdout or a file.

set -euo pipefail

OUT_FILE=""
PROFILE_ARG=()
while [[ "${1:-}" =~ ^- ]]; do
  case "$1" in
    -o|--output) OUT_FILE="$2"; shift 2;;
    -p|--profile) PROFILE_ARG=(--profile "$2"); shift 2;;
    -h|--help)
      echo "Usage: $0 [-p PROFILE] [-o output.jsonl]"
      exit 0;;
    *) echo "Unknown option: $1" >&2; exit 1;;
  esac
done

command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI v2 is required"; exit 1; }
command -v jq  >/dev/null 2>&1 || { echo "❌ jq is required"; exit 1; }

emit() {
  if [[ -z "$OUT_FILE" ]]; then
    echo "$1"
  else
    echo "$1" >> "$OUT_FILE"
  fi
}

aws_safe() {
  # Do not fail on permission or API errors; swallow stderr
  aws ${PROFILE_ARG[@]} "$@" 2>/dev/null || true
}

# ----- Enabled regions -----
REGIONS=$(aws_safe ec2 describe-regions --all-regions \
  --query "Regions[?OptInStatus==\`opt-in-not-required\` || OptInStatus==\`opted-in\`].RegionName" \
  --output text)

# ---------- Global services ----------
# S3 (global)
aws_safe s3api list-buckets \
| jq -c '.Buckets[]? | {service:"s3",type:"bucket",region:"global",name:.Name,creation_date:.CreationDate}' \
| while read -r line; do emit "$line"; done

# IAM (global)
aws_safe iam list-users \
| jq -c '.Users[]? | {service:"iam",type:"user",region:"global",name:.UserName,arn:.Arn,created:.CreateDate}' \
| while read -r line; do emit "$line"; done

aws_safe iam list-roles \
| jq -c '.Roles[]? | {service:"iam",type:"role",region:"global",name:.RoleName,arn:.Arn,created:.CreateDate}' \
| while read -r line; do emit "$line"; done

# Route53 (global)
aws_safe route53 list-hosted-zones \
| jq -c '.HostedZones[]? | {service:"route53",type:"hosted-zone",region:"global",id:.Id,name:.Name,private:.Config.PrivateZone}' \
| while read -r line; do emit "$line"; done

# CloudFront (global)
aws_safe cloudfront list-distributions \
| jq -c '.DistributionList.Items[]? | {service:"cloudfront",type:"distribution",region:"global",id:.Id,domain:.DomainName,status:.Status}' \
| while read -r line; do emit "$line"; done

# ---------- Regional services ----------
for region in $REGIONS; do
  # EC2
  aws_safe ec2 describe-instances --region "$region" \
  | jq -c --arg r "$region" '
      .Reservations[]?.Instances[]? |
      {service:"ec2",type:"instance",region:$r,id:.InstanceId,state:.State.Name,az:.Placement.AvailabilityZone,tags:.Tags}' \
  | while read -r line; do emit "$line"; done

  aws_safe ec2 describe-vpcs --region "$region" \
  | jq -c --arg r "$region" '.Vpcs[]? | {service:"ec2",type:"vpc",region:$r,id:.VpcId,cidr:.CidrBlock,tags:.Tags}' \
  | while read -r line; do emit "$line"; done

  aws_safe ec2 describe-subnets --region "$region" \
  | jq -c --arg r "$region" '.Subnets[]? | {service:"ec2",type:"subnet",region:$r,id:.SubnetId,vpc:.VpcId,cidr:.CidrBlock,az:.AvailabilityZone,tags:.Tags}' \
  | while read -r line; do emit "$line"; done

  aws_safe ec2 describe-security-groups --region "$region" \
  | jq -c --arg r "$region" '.SecurityGroups[]? | {service:"ec2",type:"security-group",region:$r,id:.GroupId,name:.GroupName,vpc:.VpcId,tags:.Tags}' \
  | while read -r line; do emit "$line"; done

  aws_safe ec2 describe-route-tables --region "$region" \
  | jq -c --arg r "$region" '.RouteTables[]? | {service:"ec2",type:"route-table",region:$r,id:.RouteTableId,vpc:.VpcId,tags:.Tags}' \
  | while read -r line; do emit "$line"; done

  aws_safe ec2 describe-internet-gateways --region "$region" \
  | jq -c --arg r "$region" '.InternetGateways[]? | {service:"ec2",type:"internet-gateway",region:$r,id:.InternetGatewayId,attachments:.Attachments}' \
  | while read -r line; do emit "$line"; done

  aws_safe ec2 describe-addresses --region "$region" \
  | jq -c --arg r "$region" '.Addresses[]? | {service:"ec2",type:"eip",region:$r,public_ip:.PublicIp,allocation_id:.AllocationId,assoc_id:.AssociationId,instance_id:.InstanceId}' \
  | while read -r line; do emit "$line"; done

  # RDS
  aws_safe rds describe-db-instances --region "$region" \
  | jq -c --arg r "$region" '.DBInstances[]? | {service:"rds",type:"db-instance",region:$r,id:.DBInstanceIdentifier,engine:.Engine,status:.DBInstanceStatus,arn:.DBInstanceArn}' \
  | while read -r line; do emit "$line"; done

  # Lambda
  aws_safe lambda list-functions --region "$region" \
  | jq -c --arg r "$region" '.Functions[]? | {service:"lambda",type:"function",region:$r,name:.FunctionName,arn:.FunctionArn,runtime:.Runtime,package_type:.PackageType}' \
  | while read -r line; do emit "$line"; done

  # DynamoDB
  aws_safe dynamodb list-tables --region "$region" \
  | jq -c --arg r "$region" '.TableNames[]? | {service:"dynamodb",type:"table",region:$r,name:.}' \
  | while read -r line; do emit "$line"; done

  # SQS
  aws_safe sqs list-queues --region "$region" \
  | jq -c --arg r "$region" '.QueueUrls[]? | {service:"sqs",type:"queue",region:$r,url:.}' \
  | while read -r line; do emit "$line"; done

  # SNS
  aws_safe sns list-topics --region "$region" \
  | jq -c --arg r "$region" '.Topics[]? | {service:"sns",type:"topic",region:$r,arn:.TopicArn}' \
  | while read -r line; do emit "$line"; done

  # ECR
  aws_safe ecr describe-repositories --region "$region" \
  | jq -c --arg r "$region" '.repositories[]? | {service:"ecr",type:"repository",region:$r,name:.repositoryName,arn:.repositoryArn,uri:.repositoryUri}' \
  | while read -r line; do emit "$line"; done

  # ECS
  aws_safe ecs list-clusters --region "$region" \
  | jq -c --arg r "$region" '.clusterArns[]? | {service:"ecs",type:"cluster",region:$r,arn:.}' \
  | while read -r line; do emit "$line"; done

  # EKS
  aws_safe eks list-clusters --region "$region" \
  | jq -c --arg r "$region" '.clusters[]? | {service:"eks",type:"cluster",region:$r,name:.}' \
  | while read -r line; do emit "$line"; done

  # API Gateway v1
  aws_safe apigateway get-rest-apis --region "$region" \
  | jq -c --arg r "$region" '.items[]? | {service:"apigateway",type:"rest-api",region:$r,id:.id,name:.name}' \
  | while read -r line; do emit "$line"; done

  # API Gateway v2 (HTTP/WebSocket)
  aws_safe apigatewayv2 get-apis --region "$region" \
  | jq -c --arg r "$region" '.Items[]? | {service:"apigatewayv2",type:"api",region:$r,id:.ApiId,name:.Name,protocol:.ProtocolType}' \
  | while read -r line; do emit "$line"; done

  # Secrets Manager
  aws_safe secretsmanager list-secrets --region "$region" \
  | jq -c --arg r "$region" '.SecretList[]? | {service:"secretsmanager",type:"secret",region:$r,arn:.ARN,name:.Name,rotation_enabled:.RotationEnabled}' \
  | while read -r line; do emit "$line"; done

  # KMS
  aws_safe kms list-keys --region "$region" \
  | jq -c --arg r "$region" '.Keys[]? | {service:"kms",type:"key",region:$r,key_id:.KeyId}' \
  | while read -r line; do emit "$line"; done
done

# Post-processing tips:
#   Filter by service:   grep '"service":"ec2"' inventory.jsonl
#   Count by type:       jq -r '.service+"."+.type' inventory.jsonl | sort | uniq -c | sort -nr
#   Load into DuckDB:    duckdb -c "CREATE TABLE inv AS SELECT * FROM read_json_auto('inventory.jsonl');"