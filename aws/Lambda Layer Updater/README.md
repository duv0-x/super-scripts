# 🔁 AWS Lambda Layer Updater

Este script automatiza la actualización de una capa (Layer) específica en funciones AWS Lambda dentro de una región y perfil determinados. Busca todas las funciones que usan una versión antigua de una capa y ofrece la opción de actualizarlas a una nueva versión.

---

### 📋 ¿Qué hace?

- Busca funciones Lambda que incluyan un ARN de layer específico (`OLD_LAYER`).
- Muestra sus capas actuales.
- Reemplaza la capa antigua por una nueva (`NEW_LAYER`) manteniendo las demás capas intactas.
- Solicita confirmación antes de actualizar cada función.
- Aplica el cambio usando `aws lambda update-function-configuration`.

---

### ⚙️ Configuración

Edita estas variables en el script según tu entorno:

```bash
OLD_LAYER="arn:aws:lambda:REGION:ACCOUNT_ID:layer:LAYER_NAME:VERSIÓN_ANTIGUA"
NEW_LAYER="arn:aws:lambda:REGION:ACCOUNT_ID:layer:LAYER_NAME:VERSIÓN_NUEVA"
SCRIPT_PROFILE="nombre-del-perfil-aws"
SCRIPT_REGION="us-west-2"
```

### ▶️ Ejecución

```bash
chmod +x update-layer.sh
./update-layer.sh
```

El script te pedirá confirmar cada actualización individualmente.

### 🔐 Requisitos
•	AWS CLI configurado con el perfil indicado (SCRIPT_PROFILE).
•	Permisos para ejecutar:
•	lambda:ListFunctions
•	lambda:GetFunctionConfiguration
•	lambda:UpdateFunctionConfiguration
•	jq instalado si decides usarlo para mejoras (aunque este script usa solo Bash y aws CLI).

> ⚠️ Nota: El script solo actualiza las funciones que ya utilizan la capa antigua. Las demás funciones permanecen sin cambios.