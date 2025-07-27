#!/bin/bash

# Este script está hecho para validar qué lambdas con el runtime $TARGET_RUNTIME NO están aterrizadas en VPC y además muestra las variables de entorno.

# Configuración
SCRIPT_PROFILE="prod"
TARGET_RUNTIME="nodejs16.x"

# Obtener todas las regiones disponibles
REGIONS=$(aws ec2 describe-regions --query 'Regions[].RegionName' --output text --profile "$SCRIPT_PROFILE")

echo "Buscando funciones Lambda con runtime '$TARGET_RUNTIME' y sin VPC usando el perfil '$SCRIPT_PROFILE'..."

# Iterar por regiones
for region in $REGIONS; do
  echo "🔍 Región: $region"

  # Listar funciones Lambda en la región
  FUNCTIONS=$(aws lambda list-functions \
    --region "$region" \
    --profile "$SCRIPT_PROFILE" \
    --query 'Functions[].FunctionName' \
    --output text)

  for function in $FUNCTIONS; do
    # Obtener configuración detallada de la función
    DETAILS=$(aws lambda get-function-configuration \
      --function-name "$function" \
      --region "$region" \
      --profile "$SCRIPT_PROFILE")

    # Extraer runtime y VPC config
    RUNTIME=$(echo "$DETAILS" | jq -r '.Runtime')
    VPC_CONFIG=$(echo "$DETAILS" | jq -r '.VpcConfig.VpcId')

    if [[ "$RUNTIME" == "$TARGET_RUNTIME" && "$VPC_CONFIG" == "null" ]]; then
      FUNCTION_ARN=$(echo "$DETAILS" | jq -r '.FunctionArn')
      ENV_VARS=$(echo "$DETAILS" | jq -r '.Environment.Variables // {}')

      echo "✅ $FUNCTION_ARN (Runtime: $RUNTIME, Región: $region, Sin VPC)"
      echo "🔐 Variables de entorno:"
      echo "$ENV_VARS" | jq .
      echo "--------------------------------------------------"
    fi
  done
done
