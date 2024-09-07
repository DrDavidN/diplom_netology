# Создаю отдельную сеть
resource "yandex_vpc_network" "net" {
  name = var.vpc_name
  folder_id = var.folder_id
}

# Создаю подсеть в регионе central1-a
resource "yandex_vpc_subnet" "central1-a" {
  name           = "central1-a"
  zone           = var.a_zone
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["10.0.10.0/24"]
}

# Создаю подсеть в регионе central1-b
resource "yandex_vpc_subnet" "central1-b" {
  name           = "central1-b"
  zone           = var.b_zone
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["10.0.20.0/24"]
}

# Создаю подсеть в регионе central1-d
resource "yandex_vpc_subnet" "central1-d" {
  name           = "central1-d"
  zone           = var.d_zone
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["10.0.30.0/24"]
}