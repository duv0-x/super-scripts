#!/bin/bash

OLD_LAYER="arn:aws:lambda:us-west-2:123456789012:layer:layer-name-prod:3"
NEW_LAYER="arn:aws:lambda:us-west-2:123456789012:layer:layer-name-prod:4"
SCRIPT_PROFILE="prod"
SCRIPT_REGION="us-west-2"

for fn in $(aws lambda list-functions \
  --profile $SCRIPT_PROFILE \
  --region $SCRIPT_REGION \
  --query "Functions[?Layers && contains(Layers[].Arn, \`${OLD_LAYER}\`)].FunctionName" \
  --output text); do

  echo "🔄 Checking function: $fn"

  # Get current layers
  current_layers=$(aws lambda get-function-configuration \
    --function-name "$fn" \
    --profile $SCRIPT_PROFILE \
    --region $SCRIPT_REGION \
    --query "Layers[].Arn" \
    --output text)

  # New list of layers with the new version
  new_layers=""
  for layer in $current_layers; do
    if [[ "$layer" == "$OLD_LAYER" ]]; then
      new_layers+="\"$NEW_LAYER\","
    else
      new_layers+="\"$layer\","
    fi
  done
  new_layers="[${new_layers%,}]"  # Deletes final coma

  echo "👉 Current layers:"
  echo "$current_layers"
  echo "✅ New setup:"
  echo "$new_layers"

  # User confirm
  read -p "¿Update this function? [y/N]: " confirm
  case "$confirm" in
    [yY][eE][sS]|[yY])
      echo "🚀 Apply..."
      aws lambda update-function-configuration \
        --function-name "$fn" \
        --layers "$new_layers" \
        --profile $SCRIPT_PROFILE \
        --region $SCRIPT_REGION
      ;;
    *)
      echo "⏭️  Jump $fn"
      ;;
  esac

  echo "-----------------------------"

done
