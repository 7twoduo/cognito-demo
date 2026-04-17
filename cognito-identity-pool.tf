# # --- Existing User Pool Resources (from your snippet) ---

# resource "aws_cognito_user_pool" "main" {
#   name                     = "${local.name}-pool"
#   auto_verified_attributes = ["email"]
#   username_attributes      = ["email"]

#   password_policy {
#     minimum_length    = 12
#     require_lowercase = true
#     require_uppercase = true
#     require_numbers   = true
#     require_symbols   = true
#   }

#   email_configuration {
#     email_sending_account = "COGNITO_DEFAULT"
#   }

#   verification_message_template {
#     default_email_option = "CONFIRM_WITH_CODE"
#   }
# }

# resource "aws_cognito_user_pool_client" "web" {
#   name         = "${local.name}-web-client"
#   user_perm_id = aws_cognito_user_pool.main.id # Fixed: this should be user_pool_id
#   user_pool_id = aws_cognito_user_pool.main.id

#   generate_secret              = true
#   allowed_oauth_flows_user_pool_client = true
#   allowed_oauth_flows         = ["code"]
#   allowed_oauth_scopes        = ["openid", "email", "aws.cognito.signin.user.admin"]
#   callback_urls               = ["${var.app_base_url}/callback"]
#   logout_urls                 = ["${var.app_base_url}/logout"]
#   supported_identity_providers = ["COGNITO"]
# }

# resource "aws_cognito_user_pool_domain" "main" {
#   domain       = var.cognito_domain_prefix
#   user_pool_id = aws_cognito_user_pool.main.id
# }

# # --- NEW: Cognito Identity Pool Resources ---

# # 1. The Identity Pool itself
# resource "aws_cognito_identity_pool" "main" {
#   identity_pool_name = "${local.name}-identity-pool"

#   # This links the Identity Pool to your User Pool
#   cognito_identity_providers {
#     client_id = aws_cognito_user_pool_client.web.client_id
#     provider  = aws_cognito_user_pool.main.id
#   }

#   # Set to true if you want guests (unauthenticated users) to access AWS resources
#   allow_unauthenticated_identities = true 
# }

# # 2. IAM Role for Authenticated Users (Users who logged in via User Pool)
# resource "aws_iam_role" "authenticated" {
#   name = "${local.name}-auth-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRoleWithWebIdentity"
#         Effect = "Allow"
#         Principal = {
#           Federated = "cognito-identity.amazonaws.com"
#         }
#         Condition = {
#           StringEquals = {
#             "cognito-identity.amazonaws.com:aud" : aws_cognito_identity_pool.main.id
#           }
#           ForceSync = false
#           "cognito-identity.amazonaws.com:sub" : "*" # In production, restrict this to specific identities if needed
#         }
#       }
#     ]
#   })
# }

# # 3. IAM Role for Unauthenticated Users (Guests)
# resource "aws_iam_role" "unauthenticated" {
#   name = "${local.name}-unauth-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRoleWithWebIdentity"
#         Effect = "Allow"
#         Principal = {
#           Federated = "cognito-identity.amazonaws.com"
#         }
#         Condition = {
#           StringEquals = {
#             "cognito-identity.amazonaws.com:aud" : aws_cognito_identity_pool.main.id
#           }
#           ForceSync = false
#           "cognito-identity.amazonaws.com:sub" : "*"
#         }
#       }
#     ]
#   })
# }

# # 4. Mapping the Roles to the Identity Pool
# resource "aws_cognito_identity_pool_roles" "main" {
#   identity_pool_id = aws_cognito_identity_pool.main.id

#   role_id = aws_iam_role.authenticated.arn
#   unauthenticated_role_id = aws_iam_role.unauthenticated.arn
# }

# # 5. (Optional) Example Policy: Give Authenticated users access to an S3 Bucket
# resource "aws_iam_role_policy" "authenticated_s3_access" {
#   name = "S3AccessPolicy"
#   role = aws_iam_role.authenticated.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action   = ["s3:GetObject", "s3:PutObject"]
#         Effect   = "Allow"
#         Resource = ["arn:aws:s3:::your-app-bucket/*"]
#       }
#     ]
#   })
# }



#           Still under development
#           Still under development
#           Still under development
#           Still under development
#           Still under development
#           Still under development
#           Still under development
#           Still under development
#           Still under development
#           Still under development
#           Still under development