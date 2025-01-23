provider "aws" {
  region = "us-east-1"
}

# Configurações de autenticação podem ser feitas via variáveis de ambiente ou perfil.
# Exemplo de variáveis de ambiente:
# AWS_ACCESS_KEY_ID=your-access-key-id
# AWS_SECRET_ACCESS_KEY=your-secret-access-key