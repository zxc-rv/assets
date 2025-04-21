#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import subprocess
import re
import time
import sys

# Простая реализация цветов через ANSI-коды (работает в большинстве терминалов Linux)
class Colors:
    CYAN = '\033[36m'
    GREEN = '\033[32m'
    YELLOW = '\033[33m'
    RED = '\033[31m'
    RESET = '\033[0m'

# Категории доменов
local_domains = [
    "youtube.com",
    "twitch.tv",
    "x.com",
    "reddit.com",
    "github.com",
    "vk.com",
    "2ip.ru",
    "amd.com",
    "nvidia.com",
    "google.com",
    "yandex.ru",
    "yahoo.com",
    "bing.com",
    "duckduckgo.com",
    "yahoo.com",
    "microsoft.com",
    "apple.com",
    "amazon.com",
    "tiktok.com",
    "linkedin.com",
    "pinterest.com",
    "deviantart.com",
    "tumblr.com",
    "wordpress.com"
]

remote_domains = [
    "jut.su",
    "gemini.google.com",
    "intel.com",
    "spotify.com",
    "grok.com",
    "chatgpt.com",
    "t3.chat",
    "ip.me",
    "trae.ai",
    "codeium.com",
    "habr.com",
    "mail.proton.me",
    "jetbrains.com",
    "augmentcode.com",
    "orbit-games.com",
    "whoer.net",
    "anthropic.com",
    "groq.com",
    "x.ai",
    "broadcom.com",
    "habr.com",
    "www.instagram.com",
    "instagram.com"
]

domains = local_domains + remote_domains
results = {}

# Находим максимальную длину домена для красивого форматирования
max_domain_length = max(len(domain) for domain in domains)

def test_domains(domain_list, category_name):
    """Проверка списка доменов с отображением прогресса"""
    print(f"\n{Colors.CYAN}Выполнение запросов [{category_name}]:{Colors.RESET}")
    total = len(domain_list)

    for i, domain in enumerate(domain_list):
        current = i + 1
        percentage = round((current / total) * 100)
        progress_text = f"[{category_name}] Обработка: {domain} ({current}/{total}, {percentage}%)"
        # Добавляем пробелы для перекрытия предыдущей строки
        padded_text = progress_text.ljust(80)
        print(f"\r{padded_text}", end="", flush=True)

        try:
            # Запуск dig в тихом режиме, только со статистикой
            cmd = ["dig", domain, "+noall", "+stats"]
            process = subprocess.run(cmd, capture_output=True, text=True)

            if process.returncode != 0:
                raise Exception(f"Ошибка выполнения dig для домена {domain}")

            # Ищем время запроса
            match = re.search(r";; Query time: (\d+) msec", process.stdout)

            if match:
                query_time = match.group(1).strip()
                results[domain] = f"{query_time} msec"
            else:
                # Если статистика не найдена, пробуем другой подход
                cmd = ["dig", domain]
                process = subprocess.run(cmd, capture_output=True, text=True)

                if process.returncode != 0:
                    raise Exception(f"Ошибка выполнения dig для домена {domain}")

                match = re.search(r";; Query time: (\d+) msec", process.stdout)

                if match:
                    query_time = match.group(1).strip()
                    results[domain] = f"{query_time} msec"
                else:
                    results[domain] = "Нет данных"
        except Exception as e:
            results[domain] = f"Ошибка: {str(e)}"

    print(f"\r{Colors.GREEN}Запросы [{category_name}] завершены!{' ' * 40}{Colors.RESET}")

def calculate_average_time(domain_list):
    """Расчет среднего времени отклика для списка доменов"""
    total_time = 0
    valid_domains = 0

    for domain in domain_list:
        result = results.get(domain, "Нет данных")
        if "msec" in result:
            try:
                time_value = int(result.split()[0])
                total_time += time_value
                valid_domains += 1
            except (ValueError, IndexError):
                continue

    if valid_domains > 0:
        return total_time / valid_domains
    return 0

def print_results():
    """Вывод результатов запросов"""
    print(f"\n{Colors.CYAN}=============== Результаты запросов DNS ===============\n{Colors.RESET}")

    # Вывод локальных доменов
    print(f"{Colors.GREEN}Категория: Local{Colors.RESET}")
    print("------------------------")
    for domain in local_domains:
        result = results.get(domain, "Нет данных")
        padding = " " * (max_domain_length - len(domain))
        print(f"{domain}{padding} : {result}")

    # Вывод удаленных доменов
    print(f"\n{Colors.YELLOW}Категория: Remote{Colors.RESET}")
    print("------------------------")
    for domain in remote_domains:
        result = results.get(domain, "Нет данных")
        padding = " " * (max_domain_length - len(domain))
        print(f"{domain}{padding} : {result}")

    # Вывод средних значений времени ответа
    print(f"\n{Colors.CYAN}Средние значения времени ответа:{Colors.RESET}")
    print("------------------------")
    local_avg = calculate_average_time(local_domains)
    remote_avg = calculate_average_time(remote_domains)
    print(f"{Colors.GREEN}Локальные домены: {local_avg:.2f} msec{Colors.RESET}")
    print(f"{Colors.YELLOW}Удаленные домены: {remote_avg:.2f} msec{Colors.RESET}")

def main():
    # Проверка наличия команды dig
    try:
        subprocess.run(["dig", "-v"], capture_output=True)
    except FileNotFoundError:
        print(f"{Colors.RED}Ошибка: Команда 'dig' не найдена. Пожалуйста, установите пакет bind-utils или dnsutils.{Colors.RESET}")
        print("В Ubuntu/Debian: sudo apt-get install dnsutils")
        print("В CentOS/RHEL/Fedora: sudo yum install bind-utils")
        print("В Arch Linux: sudo pacman -S bind")
        print("Для OpenWrt/роутеров: opkg install bind-dig")
        sys.exit(1)

    # Проверка доменов по категориям
    test_domains(local_domains, "Local")
    test_domains(remote_domains, "Remote")

    # Вывод результатов
    print_results()

if __name__ == "__main__":
    main()
