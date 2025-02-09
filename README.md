# Upload de Arquivos - Microserviços

Este projeto é um serviço de upload de arquivos que utiliza AWS S3 para armazenamento e AWS SQS para processamento de mensagens. Abaixo estão as instruções sobre como configurar e utilizar os serviços.

## Estrutura do Projeto: Arquitetura Ports e Adapters

- `src/app/ports`: Contém as interfaces para os adaptadores.
- `src/app/domain/entities.py`: Contém a entidade `File`.
- `src/app/domain/services.py`: Contém o serviço `UploadService`.
- `src/app/controllers/lambda_handler.py`: Contém o handler para a função Lambda.
- `src/app/adapters/s3_adapter.py`: Contém o adaptador para o S3.
- `src/app/adapters/sqs_adapter.py`: Contém o adaptador para o SQS.

## Tecnologias Utilizadas

- Implementação: Lambda AWS
- Serviço de Armazenamento: Bucket S3
- IaC: Infraestrutura como código

### Pré-requisitos

Certifique-se de instalar e ter acesso no ambiente.
- Python
- Terraform
- Acesso a AWS

### Dependências

Instale as dependências necessárias utilizando `pip`:

```bash
pip install boto3
pip install pytest
```

## Utilização

1- Clone o repositório:
```bash
git clone https://github.com/hackaton-fiap-6soat/upload-file.git
cd upload-file
```
2- Infraestrutura:
```bash
cd terraform
terraform init
terraform apply
```

### Deploy automátiuco com o GitHub Actions

O deploy é realizado de maneira automática através do GitHub Actions. Ao fazer o comando git push para a branch main o processo é definito em .github/workflows/deploy.yaml



### Licença

Este projeto está licenciado sob a MIT License - veja o arquivo LICENSE para mais detalhes.

