#!/bin/bash

OLD_LAYER="arn:aws:lambda:us-west-2:674533299795:layer:cache-extension-prod:3"
NEW_LAYER="arn:aws:lambda:us-west-2:674533299795:layer:cache-extension-prod:4"
SCRIPT_PROFILE="prod"
SCRIPT_REGION="us-west-2"

for fn in $(aws lambda list-functions \
  --profile $SCRIPT_PROFILE \
  --region $SCRIPT_REGION \
  --query "Functions[?Layers && contains(Layers[].Arn, \`${OLD_LAYER}\`)].FunctionName" \
  --output text); do

  echo "🔄 Revisando función: $fn"

  # Obtener las layers actuales
  current_layers=$(aws lambda get-function-configuration \
    --function-name "$fn" \
    --profile $SCRIPT_PROFILE \
    --region $SCRIPT_REGION \
    --query "Layers[].Arn" \
    --output text)

  # Construir nueva lista de layers con la nueva versión
  new_layers=""
  for layer in $current_layers; do
    if [[ "$layer" == "$OLD_LAYER" ]]; then
      new_layers+="\"$NEW_LAYER\","
    else
      new_layers+="\"$layer\","
    fi
  done
  new_layers="[${new_layers%,}]"  # Elimina la coma final

  echo "👉 Layers actuales:"
  echo "$current_layers"
  echo "✅ Nueva configuración:"
  echo "$new_layers"

  # Preguntar confirmación
  read -p "¿Actualizar esta función? [y/N]: " confirm
  case "$confirm" in
    [yY][eE][sS]|[yY])
      echo "🚀 Aplicando cambio..."
      aws lambda update-function-configuration \
        --function-name "$fn" \
        --layers "$new_layers" \
        --profile $SCRIPT_PROFILE \
        --region $SCRIPT_REGION
      ;;
    *)
      echo "⏭️  Saltando $fn"
      ;;
  esac

  echo "-----------------------------"

done
