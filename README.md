# Deploy Java Application on AWS 3-Tier Architecture com Terraform

![AWS Architecture](https://imgur.com/b9iHwVc.png)

## Visao Geral
Este projeto provisiona uma arquitetura 3-tier na AWS com Terraform para executar uma aplicacao Java (Spring Boot/JSP) em ambiente escalavel.

Arquitetura implementada neste repositorio:
- Camada Web: Nginx em Auto Scaling Group atras de NLB publico
- Camada App: Tomcat em Auto Scaling Group atras de NLB interno
- Camada Dados: RDS MySQL Multi-AZ em VPC separada
- Rede: 2 VPCs conectadas por Transit Gateway
- Operacao: VPC Flow Logs, IAM para SSM e CloudWatch

## Estrutura
```text
.
├── Java-Login-App/
├── modules/
│   ├── vpc/
│   ├── app-tier/
│   ├── rds/
│   └── bastion/
├── environments/
│   ├── dev/
│   └── prod/
└── scripts/
    ├── userdata_frontend.sh.tpl
    ├── userdata_backend.sh.tpl
    └── metrics.sh
```

## Pre-Requisitos
- Terraform >= 1.5
- AWS CLI autenticado (`aws configure` ou SSO)
- Permissoes IAM para VPC, EC2, ELBv2, Auto Scaling, IAM, RDS, CloudWatch, SSM, TGW

## Como executar (DEV)
1. Entrar no ambiente:
```bash
cd environments/dev
```

2. Criar arquivos locais (nao versionados):
```bash
cp terraform.tfvars.example terraform.tfvars
cp backend.tf.example backend.tf
```

3. Editar `terraform.tfvars` e `backend.tf`:
- Definir `db_password`
- Ajustar CIDRs/subnets se necessario
- Definir bucket/tabela de lock do backend remoto

4. Inicializar, validar e planejar:
```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan -var-file=terraform.tfvars
```

5. Aplicar:
```bash
terraform apply -var-file=terraform.tfvars
```

6. Obter endpoints:
```bash
terraform output
```

## Como executar (PROD)
Mesmo fluxo em `environments/prod`:
```bash
cd environments/prod
cp terraform.tfvars.example terraform.tfvars
cp backend.tf.example backend.tf
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## Deploy da aplicacao Java
Build local:
```bash
cd Java-Login-App
mvn clean package -DskipTests
```

Opcoes de deploy no backend:
- Informar `java_artifact_url` no `terraform.tfvars` para baixar WAR/JAR no bootstrap das instancias
- Ou usar pipeline CI/CD para publicar artefato e atualizar Launch Template/ASG

## Seguranca
- Credenciais de banco removidas do `application.properties` (agora via variaveis de ambiente)
- RDS privado em VPC de dados
- Acesso administrativo por SSM (e bastion opcional)
- Flow logs habilitados para as duas VPCs

## Observacoes
- O recurso Route53 esta no codigo com `count = 0` para servir de placeholder.
- CloudFront e ElastiCache nao foram habilitados neste baseline para manter menor custo/complexidade inicial.
- Para destruir recursos:
```bash
terraform destroy -var-file=terraform.tfvars
```
