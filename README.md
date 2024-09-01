# Infrastructure Setup using Terraform, Helm, and AWS EKS

This repository contains Terraform scripts for deploying and managing a complete infrastructure on AWS, including the provisioning of an EKS (Elastic Kubernetes Service) cluster and the deployment of various applications using Helm. The applications include Kafka, PostgreSQL, Cluster Autoscaler, Fluent Bit, Prometheus, Istio, and Metrics Server, configured with custom values to match specific operational needs.

## Table of Contents

- [Infrastructure Setup using Terraform, Helm, and AWS EKS](#infrastructure-setup-using-terraform-helm-and-aws-eks)
  - [Table of Contents](#table-of-contents)
  - [Infrastructure Overview](#infrastructure-overview)
  - [Pre-requisites](#pre-requisites)
  - [Installation](#installation)
  - [Resources](#resources)
    - [EKS Cluster](#eks-cluster)
    - [Kafka](#kafka)
    - [PostgreSQL](#postgresql)
    - [Cluster Autoscaler](#cluster-autoscaler)
    - [Fluent Bit](#fluent-bit)
    - [Prometheus](#prometheus)
    - [Kafka Exporter](#kafka-exporter)
    - [Istio](#istio)
    - [Metrics Server](#metrics-server)
  - [Configuration](#configuration)
  - [Usage](#usage)
  - [Dependencies](#dependencies)

## Infrastructure Overview

This Terraform setup manages the deployment of an AWS EKS cluster and various Kubernetes applications using Helm charts. The setup is designed to provide a robust, scalable infrastructure that supports essential services like Kafka for messaging, PostgreSQL for database management, and Prometheus for monitoring.

## Pre-requisites

Before running this Terraform configuration, ensure you have the following:

- Terraform 
- Helm 
- AWS CLI configured with appropriate credentials


## Installation

1. Clone the Repository:
    ```bash
    git clone <repository-url>
    cd <repository-directory>
    ```
2. Initialize Terraform:
    ```bash
    terraform init
    ```
3. Apply the Terraform Configuration:
    ```bash
    terraform apply
    ```
   This will create the EKS cluster and deploy the configured Helm releases on the Kubernetes cluster.

## Resources

### EKS Cluster

- **Service**: AWS EKS
- **Configuration**:
  - Provisions an EKS cluster with worker nodes.
  - Configures IAM roles and security groups for secure communication.
  - Manages networking with VPC, subnets, and route tables.
  - Supports auto-scaling and load balancing for deployed services.

### Kafka

- **Chart**: Bitnami Kafka
- **Namespace**: kafka
- **Configuration**:
  - Enabled PLAINTEXT listeners for client, controller, and inter-broker communication.
  - Configured Kafka provisioning with replication factor and partitions.
  - Persistence and resource limits for the Kafka controller.
  - Metrics are enabled with JMX.

### PostgreSQL

- **Chart**: Bitnami PostgreSQL
- **Namespace**: webapp_cve_consumer
- **Configuration**:
  - Configured global PostgreSQL authentication with username, password, and database.
  - Resource presets set to medium.
  - Metrics collection enabled.

### Cluster Autoscaler

- **Chart**: Custom Helm chart hosted on GitHub
- **Namespace**: cluster_autoscaler
- **Configuration**:
  - Configured with AWS region and EKS cluster auto-discovery.
  - Service account with appropriate IAM role.

### Fluent Bit

- **Chart**: Custom CloudWatch integration chart hosted on GitHub
- **Namespace**: cloud_watch
- **Configuration**:
  - Connects to CloudWatch for log aggregation and monitoring.

### Prometheus

- **Chart**: Kube-Prometheus-Stack from Prometheus Community
- **Namespace**: monitoring
- **Configuration**:
  - Configured to scrape metrics from Kafka and PostgreSQL.

### Kafka Exporter

- **Chart**: Prometheus Kafka Exporter
- **Namespace**: monitoring
- **Configuration**:
  - Kafka server targets configured.
  - Prometheus service monitor enabled.

### Istio

- **Charts**:
  - Istio Base: Base chart for Istio installation.
  - Istiod: Istio control plane.
  - Istio Ingress Gateway: Configured for AWS NLB with external DNS annotations.
- **Namespace**: istio
- **Configuration**:
  - Hold application until proxy starts.
  - Configured with logging as JSON.

### Metrics Server

- **Chart**: Metrics Server
- **Namespace**: cluster_autoscaler
- **Configuration**:
  - Deployed to collect resource metrics across the cluster.

## Configuration

Modify the variables in the `terraform.tfvars` file to adjust the deployment configurations, such as versions, namespaces, resource limits, and other Helm values. The configuration also includes settings for the EKS cluster, such as node instance types, number of nodes, and networking configurations.

## Usage

After deployment, the EKS cluster will be up and running, and various services will be deployed within their respective namespaces on the Kubernetes cluster. You can monitor the deployment using tools like `kubectl`, Prometheus, or AWS CloudWatch.

## Dependencies

This setup relies on:

- **AWS EKS**: The Kubernetes platform where the services are deployed.
- **Helm**: The package manager for Kubernetes used to deploy the services.
- **Terraform Modules**:
  - EKS Module for setting up the Kubernetes cluster.
  - Helm Provider for managing Helm releases.
  - AWS modules for VPC, IAM roles, and security groups.

