# Imagem oficial do PHP com Apache
FROM php:8.3-apache

# Dependências do sistema
RUN apt-get update && apt-get install -y \
    git \
    curl \
    zip \
    unzip \
    libsqlite3-dev \
    libpq-dev \
    libzip-dev \
    && docker-php-ext-install pdo_sqlite pdo_pgsql pdo_mysql zip

# Instala o Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copia todos os arquivos do projeto
COPY . .

# Instala as dependências do Laravel
RUN composer install --no-dev --optimize-autoloader

# Ajusta as permissões para o servidor web
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage \
    && chmod -R 775 /var/www/html/bootstrap/cache

# Ativa o módulo Rewrite do Apache
RUN a2enmod rewrite

# Copia a configuração do VirtualHost (Onde costuma estar o erro "Menu")
COPY .docker/vhost.conf /etc/apache2/sites-available/000-default.conf

# Limpa caches antigos de arquivos
RUN rm -f bootstrap/cache/*.php

EXPOSE 80

# Comando de inicialização: Migra o banco e liga o servidor
CMD bash -c "php artisan migrate --force && php artisan config:clear && php artisan cache:clear && apache2-foreground"
