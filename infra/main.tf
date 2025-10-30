# Configuración de Terraform
# Sin esto fallaria, es como decir que version de un app necesitas.
terraform {
  # Le decimos que necesitamos version 1.5.0 o superior
  required_version = ">= 1.5.0"
  # Aqui se define que plugins necesitaremos para funcionar
  required_providers {
    # Plugin para AWS
    aws = {
      # Le dice de donde descargar el "plugin" (Hashicorp es la empresa que hizo Terraform) 
      source = "hashicorp/aws"
      # Usa version 5.50 o similar (version compatible)
      version = "~> 5.50"
    }
  }
}

# Configuracion del proveedor AWS
# Le dice a Terraform que va usar AWS 
provider "aws" {
  # Define en que region geografica de Amazon crear las cosas
  region = var.region
}

# Buscar la imagen de sistema operativo
# Si no se pone esto no tendra sistema operativo para instalar la maquina virtual.
data "aws_ami" "al2023" {
  # Busca la imagen mas reciente
  most_recent = true
  # Solo busca imagenes oficiales de Amazon (ID de Amazon)
  owners = ["137112412989"]

  # Aplicar filtros para encontrar exactamente lo que se requiere
  filter {
    name = "name"
    # Busca Amazon Linux 2023 con kernel 6.1 y arquitectura x86_64
    values = ["al2023-ami-*-kernel-6.1-x86_64"]
  }
}

# Crea un par de llaves para conectarse de forma segura (SSH = Secure Shell)
# Sin esto no se podra conectar de forma segura a la maquina virtual.
resource "aws_key_pair" "this" {
  # Le pone nombre a la llave usando el nombre del proyecto
  key_name = "${var.project_name}-key"
  # Define cual es la llave publica (como dar tu direccion para que te envien las cartas)
  public_key = var.public_ssh_key
}

# Red virtual por defecto
# Usa la que viene por defecto con Amazon
resource "aws_default_vpc" "default" {}

# Buscar zonas disponibles
# Busca centros de datos estan disponibles en la region -> Buscar que tiendas tiene la ciudad.
data "aws_availability_zones" "available" {}

# Subred por defecto -> Sin esto la maquina no tendra una direccion especifica dentro de la red
# Usa la subred por defecto (como un barrio dentro de una ciudad)
resource "aws_default_subnet" "default_az1" {
  # La coloca en el primer centro de datos disponible
  availability_zone = data.aws_availability_zones.available.names[0]
}

# Grupo de seguridad (firewall) -> Reglas de seguridad de la casa.
resource "aws_security_group" "this" {
  name        = "${var.project_name}-sg"
  description = "Security group para el proyecto ${var.project_name}"

  # Reglas de entrada (ingress)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    # Tipo de conexcion (TCP) como el idioma que van hablar
    protocol = "tcp"
    # Desde que direcciones IP pueden entrar
    cidr_blocks = [var.admin_cidr_ssh]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port = 0
    to_port   = 0
    # -1 significa que permite cualquier protocolo
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-sg"
    Project = var.project_name
  }
}

# Script de configuracion -> Define como variables locales
locals {
  # Script que se ejecutar al arranchar 
  user_data = <<-EOT
    #!/bin/bash
    # Le decimos que use el interprete de bash 

    # Configuracion para el script para que se detenga si hay un error
    set -euxo pipefail

    # Actualiza el sistema operativo
    dnf update -y
    
    # Instala Docker
    dnf install -y docker
    
    # Hace que Docker se inicie automaticamente al arranchar la maquina
    systemctl enable docker
    
    # Inicia Docker
    systemctl start docker

    # Le da permisos al usuario para usar docker
    # Agrega el usuario ec2-user al grupo docker
    usermod -aG docker ec2-user
  EOT
}

# Creamos una maquina virtual (EC2 = Elastic Compute Cloud , Computadora en la nube)
resource "aws_instance" "this" {
  # Usa la imagen de sistema operativo que busco antes
  ami = data.aws_ami.al2023.id
  # Tamaño de la maquina virtual -> t3.micro es la mas pequeña
  instance_type = "t3.micro"
  # Usa las llaves SSH que creo antes
  key_name = aws_key_pair.this.key_name
  # Aplica las reglas de firewall que creo antes
  vpc_security_group_ids = [aws_security_group.this.id]
  # Ejecuta el script  de configuracion al arrancar
  user_data = local.user_data

  # Los tags son metadatos clave/valor que se adjuntan a los recursos de AWS
  # Sirven para identificar, organizar, filtrar, auditar y costear recursos.
  tags = {
    Name    = "${var.project_name}-ec2"
    Project = var.project_name
  }
}
