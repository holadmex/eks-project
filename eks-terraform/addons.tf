# EKS Addons
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.eks.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.eks.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on                  = [aws_eks_node_group.eks_nodes_1]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.eks.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name                = aws_eks_cluster.eks.name
  addon_name                  = "aws-ebs-csi-driver"
  service_account_role_arn    = aws_iam_role.ebs_csi_driver.arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

# Karpenter Helm Chart
resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = "v0.32.0"
  timeout          = 600
  wait             = true

  values = [
    yamlencode({
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.karpenter.arn
        }
      }
      settings = {
        aws = {
          clusterName            = aws_eks_cluster.eks.name
          defaultInstanceProfile = aws_iam_instance_profile.karpenter.name
        }
      }
    })
  ]

  depends_on = [aws_eks_node_group.eks_nodes_1]
}

# Karpenter Instance Profile
resource "aws_iam_role" "karpenter_node" {
  name = "${var.cluster_name}-karpenter-node"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "karpenter" {
  name = "${var.cluster_name}-karpenter-node-instance-profile"
  role = aws_iam_role.karpenter_node.name
}

resource "aws_iam_role_policy_attachment" "karpenter_node_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.karpenter_node.name
}

resource "aws_iam_role_policy_attachment" "karpenter_node_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.karpenter_node.name
}

resource "aws_iam_role_policy_attachment" "karpenter_node_registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.karpenter_node.name
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.karpenter_node.name
}

# # Velero Helm Chart
# resource "helm_release" "velero" {
#   namespace        = "velero"
#   create_namespace = true
#   name             = "velero"
#   repository       = "https://vmware-tanzu.github.io/helm-charts"
#   chart            = "velero"
#   version          = "5.1.0"
#   timeout          = 600
#   wait             = true

#   values = [
#     yamlencode({
#       serviceAccount = {
#         server = {
#           annotations = {
#             "eks.amazonaws.com/role-arn" = aws_iam_role.velero.arn
#           }
#         }
#       }
#       configuration = {
#         backupStorageLocation = [{
#           name     = "default"
#           provider = "aws"
#           bucket   = aws_s3_bucket.velero_backups.bucket
#           config = {
#             region = var.region
#           }
#         }]
#         volumeSnapshotLocation = [{
#           name     = "default"
#           provider = "aws"
#           config = {
#             region = var.region
#           }
#         }]
#       }
#       initContainers = [{
#         name  = "velero-plugin-for-aws"
#         image = "velero/velero-plugin-for-aws:v1.8.0"
#         volumeMounts = [{
#           mountPath = "/target"
#           name      = "plugins"
#         }]
#       }]
#     })
#   ]

#   depends_on = [aws_eks_node_group.eks_nodes_1]
# }

# # S3 Bucket for Velero backups
# resource "aws_s3_bucket" "velero_backups" {
#   bucket = "${var.cluster_name}-velero-backups-${random_id.bucket_suffix.hex}"

#   tags = {
#     Name = "${var.cluster_name}-velero-backups"
#   }
# }

# resource "random_id" "bucket_suffix" {
#   byte_length = 2
# }

# resource "aws_s3_bucket_versioning" "velero_backups" {
#   bucket = aws_s3_bucket.velero_backups.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# resource "aws_s3_bucket_encryption" "velero_backups" {
#   bucket = aws_s3_bucket.velero_backups.id

#   server_side_encryption_configuration {
#     rule {
#       apply_server_side_encryption_by_default {
#         kms_master_key_id = aws_kms_key.eks.arn
#         sse_algorithm     = "aws:kms"
#       }
#     }
#   }
# }

# resource "aws_s3_bucket_public_access_block" "velero_backups" {
#   bucket = aws_s3_bucket.velero_backups.id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }