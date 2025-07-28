# 🔁 AWS Lambda Layer Updater

This script automates the update of a specific Lambda **Layer** across AWS Lambda functions within a given region and profile. It scans for functions using an old version of a layer and offers the option to update them to a new version.

---

### 📋 What Does It Do?

- Searches for Lambda functions that include a specific **old layer ARN** (`OLD_LAYER`).
- Displays their current list of layers.
- Replaces the old layer with the **new one** (`NEW_LAYER`), keeping the rest unchanged.
- Prompts for confirmation before updating each function.
- Applies the change using `aws lambda update-function-configuration`.

---

### ⚙️ Setup

Edit these variables in the script according to your environment:
```bash
OLD_LAYER="arn:aws:lambda:REGION:ACCOUNT_ID:layer:LAYER_NAME:VERSIÓN_ANTIGUA"
NEW_LAYER="arn:aws:lambda:REGION:ACCOUNT_ID:layer:LAYER_NAME:VERSIÓN_NUEVA"
SCRIPT_PROFILE="nombre-del-perfil-aws"
SCRIPT_REGION="us-west-2"
```

### ▶️ Execution

```bash
chmod +x update-layer.sh
./update-layer.sh
```

> ⚠️ The script will ask for confirmation before updating each function individually.

### 🔐 Requirements
- AWS CLI configured with the specified profile (SCRIPT_PROFILE)
- Permissions for:
- lambda:ListFunctions
- lambda:GetFunctionConfiguration
- lambda:UpdateFunctionConfiguration
- jq is optional (not used in this script but may be useful for enhancements)

> ⚠️ The script only updates functions that already use the old layer. Other functions remain unchanged.