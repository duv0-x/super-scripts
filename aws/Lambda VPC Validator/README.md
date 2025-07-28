# 🛡️ Lambda VPC Validator

This Bash script helps identify **AWS Lambda functions** that:

- Use a specific runtime (default: `nodejs16.x`)
- **Are not attached to a VPC**
- And displays their environment variables

Perfect for security audits and infrastructure reviews across all AWS regions.

---

### 🚀 What It Does

1. Iterates over **all available AWS regions**.
2. Filters Lambda functions by the specified runtime.
3. Detects those **not configured with a VPC**.
4. Prints the function's ARN and its **environment variables**.

---

### ⚙️ Requirements

- AWS CLI configured with a valid named profile.
- [`jq`](https://stedolan.github.io/jq/) installed (for JSON parsing).
- AWS permissions for:
    - `ec2:DescribeRegions`
    - `lambda:ListFunctions`
    - `lambda:GetFunctionConfiguration`

---

### 📦 Usage

```bash
./lambda-vpc-validator.sh
```

Optionally, modify the following at the top of the script:

```bash
SCRIPT_PROFILE="prod"          # AWS CLI profile to use
TARGET_RUNTIME="nodejs16.x"    # Target runtime (e.g., python3.12, nodejs18.x)
```

### 📌 Notes
•	Functions already attached to a VPC are skipped.
•	Regions with no Lambda functions will be silently ignored.
•	You can customize the script to target other runtimes like python3.9, go1.x, etc.