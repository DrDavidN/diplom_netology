# Создаю сервисный аккаунт для terraform
resource "yandex_iam_service_account" "tf-sa" {
  name = "tf-sa"
}

# Выдаю роль для сервисного аккаунта tf
resource "yandex_resourcemanager_folder_iam_member" "tf-sa-editor" {
  folder_id  = var.folder_id
  role       = "editor"
  member     = "serviceAccount:${yandex_iam_service_account.tf-sa.id}"
  depends_on = [yandex_iam_service_account.tf-sa]
}

# Создаю ключ для аккаунта
resource "yandex_iam_service_account_static_access_key" "tf-key" {
  service_account_id = yandex_iam_service_account.tf-sa.id
  depends_on         = [yandex_resourcemanager_folder_iam_member.tf-sa-editor]
}

# Создаю бакет
resource "yandex_storage_bucket" "s3-backet" {
  bucket     = var.bucket_name
  access_key = yandex_iam_service_account_static_access_key.tf-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.tf-key.secret_key

  anonymous_access_flags {
    read = false
    list = false
  }
  force_destroy = true
  depends_on    = [yandex_iam_service_account_static_access_key.tf-key]
}

# Сохраняем статические ключи подключения в основной проект terraform
resource "local_file" "backend-conf" {
  content    = <<EOT
access_key = "${yandex_iam_service_account_static_access_key.tf-key.access_key}"
secret_key = "${yandex_iam_service_account_static_access_key.tf-key.secret_key}"
EOT
  filename   = "../terraform/backend.key"
  depends_on = [yandex_storage_bucket.s3-backet]
}

# Генерируем авторизованный ключ для подключения в дальнейшем проекте под учеткой tf-sa
resource "null_resource" "example" {
  provisioner "local-exec" {
    command = "yc iam key create --folder-name diplom --service-account-name tf-sa --output ../terraform/key.json"
  }
  depends_on = [yandex_resourcemanager_folder_iam_member.tf-sa-editor]
}

