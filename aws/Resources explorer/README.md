# 🗂 AWS Multi-Region Resources Explorer

This Bash script scans **all enabled AWS regions** and **global services** to list commonly used AWS resources in **JSONL** format (one JSON object per line).  
It’s useful for quickly auditing resources across an entire AWS account without manually switching regions.

---

## ✨ Features

- **Multi-region** scan using `describe-regions`
- **Global services** included:
    - S3 buckets
    - IAM users & roles
    - Route53 hosted zones
    - CloudFront distributions
- **Regional services** included:
    - EC2 instances, VPCs, subnets, security groups, route tables, internet gateways, EIPs
    - RDS instances
    - Lambda functions
    - DynamoDB tables
    - SQS queues
    - SNS topics
    - ECR repositories
    - ECS clusters
    - EKS clusters
    - API Gateway (v1 & v2)
    - Secrets Manager secrets
    - KMS keys
- Output in **machine-friendly** JSON Lines
- Works with **AWS profiles** and **AWS SSO**
- Gracefully skips services without permissions

---

## 📦 Requirements

- **AWS CLI v2** configured with credentials (`aws configure` or `aws configure sso`)
- **jq** installed
- Permissions to list resources for the desired services

---

## 🚀 Usage

Make the script executable:
```bash
chmod +x resources-explorer.sh
```
Run with your default AWS profile:
```bash
./resources-explorer.sh
```
Run with a specific profile and output to a file:
```bash
AWS_PROFILE=my-profile ./resources-explorer.sh -o inventory.jsonl
```
Run with an explicit profile argument:
```bash
./resources-explorer.sh -p my-profile -o inventory.jsonl
```

## 📂 Output Format

The script outputs **one JSON object per line**:

```json
{"service":"ec2","type":"instance","region":"us-east-1","id":"i-0123456789abcdef0","state":"running","az":"us-east-1a","tags":[{"Key":"Name","Value":"MyServer"}]}
{"service":"s3","type":"bucket","region":"global","name":"my-bucket","creation_date":"2021-06-15T10:45:00.000Z"}
```

## 🛠 Post-processing Tips

Filter for a specific service:

```bash
grep '"service":"ec2"' inventory.jsonl
```

Count resources by type:

```bash
jq -r '.service+"."+.type' inventory.jsonl | sort | uniq -c | sort -nr
```

Load into a DuckDB for querying:

```bash
duckdb -c "CREATE TABLE inv AS SELECT * FROM read_json_auto('inventory.jsonl');"
```

## ⚠️ Notes

- This is **not** a full AWS resource discovery tool; it focuses on common services.
- Some services (e.g., Redshift, Glue, Step Functions) are **not included** by default but can be added easily.
- IAM permissions will affect results — missing permissions will cause that service to be skipped for that region.
- API calls across many regions **may incur AWS API costs**.