#!/usr/bin/env python3
"""SAE Auto Script - safe Roblox utility."""
from __future__ import annotations

import json
import logging
import os
import re
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

try:
    import requests
except ImportError:
    requests = None

try:
    from colorama import Fore, init as colorama_init
except ImportError:
    class _Dummy:
        CYAN = GREEN = YELLOW = RED = ""
    Fore = _Dummy()
    def colorama_init(*_args, **_kwargs):
        pass

colorama_init(autoreset=True)

BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"
LOG_DIR = BASE_DIR / "logs"
ACCOUNTS_FILE = DATA_DIR / "accounts.json"
LOG_FILE = LOG_DIR / "sae_auto.log"
ROBLOX_GAMES_API = "https://games.roblox.com/v1/games"
REQUEST_TIMEOUT = 10


def setup_logging() -> None:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s | %(levelname)s | %(message)s",
        handlers=[
            logging.FileHandler(LOG_FILE, encoding="utf-8"),
            logging.StreamHandler(),
        ],
    )


@dataclass
class Account:
    username: str
    added_date: str
    status: str = "active"
    notes: str = ""


class AccountManager:
    """Store non-sensitive Roblox account metadata locally."""

    def __init__(self, path: Path = ACCOUNTS_FILE) -> None:
        self.path = path
        self.accounts: list[Account] = []
        self.load()

    def load(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        if not self.path.exists():
            self.accounts = []
            return
        try:
            raw = json.loads(self.path.read_text(encoding="utf-8"))
            if not isinstance(raw, list):
                raise ValueError("accounts.json must contain a JSON list")
            self.accounts = [
                Account(
                    username=str(item.get("username", "")).strip(),
                    added_date=str(
                        item.get("added_date")
                        or datetime.now(timezone.utc).isoformat()
                    ),
                    status=str(item.get("status", "active")),
                    notes=str(item.get("notes", "")),
                )
                for item in raw
                if isinstance(item, dict) and str(item.get("username", "")).strip()
            ]
        except (OSError, json.JSONDecodeError, ValueError) as exc:
            logging.error("Hesap verisi okunamadı: %s", exc)
            self.accounts = []

    def save(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        tmp = self.path.with_suffix(".tmp")
        payload = [asdict(account) for account in self.accounts]
        tmp.write_text(
            json.dumps(payload, indent=2, ensure_ascii=False),
            encoding="utf-8",
        )
        os.replace(tmp, self.path)

    def add(self, username: str, notes: str = "") -> bool:
        username = username.strip()
        if not re.fullmatch(r"[A-Za-z0-9_]{3,20}", username):
            print(Fore.RED + "Geçersiz Roblox kullanıcı adı.")
            return False
        if any(a.username.lower() == username.lower() for a in self.accounts):
            print(Fore.YELLOW + "Bu kullanıcı zaten kayıtlı.")
            return False
        self.accounts.append(
            Account(
                username=username,
                added_date=datetime.now(timezone.utc).isoformat(),
                notes=notes.strip(),
            )
        )
        self.save()
        print(Fore.GREEN + f"[+] {username} eklendi.")
        return True

    def remove(self, username: str) -> bool:
        before = len(self.accounts)
        self.accounts = [
            a for a in self.accounts
            if a.username.lower() != username.strip().lower()
        ]
        if len(self.accounts) == before:
            print(Fore.YELLOW + "Kullanıcı bulunamadı.")
            return False
        self.save()
        print(Fore.GREEN + f"[+] {username} silindi.")
        return True

    def list_accounts(self) -> None:
        print("\n" + "=" * 64)
        print(Fore.CYAN + "KAYITLI KULLANICILAR")
        print("=" * 64)
        if not self.accounts:
            print("Henüz kullanıcı yok.")
        for index, account in enumerate(self.accounts, 1):
            print(
                f"{index:>2}. {account.username:<22} | "
                f"{account.status:<8} | {account.added_date}"
            )
        print("=" * 64)


class RobloxPublicAPI:
    """Read-only access to public Roblox game information."""

    def __init__(self, timeout: int = REQUEST_TIMEOUT) -> None:
        if requests is None:
            raise RuntimeError(
                "requests paketi eksik. "
                "python -m pip install requests çalıştırın."
            )
        self.timeout = timeout
        self.session = requests.Session()
        self.session.headers.update({
            "User-Agent": "SAE-AUTO-SCRIPT/2.0",
            "Accept": "application/json",
        })

    @staticmethod
    def validate_universe_id(value: str) -> int:
        if not value.strip().isdigit():
            raise ValueError("Universe ID yalnızca rakamlardan oluşmalıdır.")
        universe_id = int(value)
        if universe_id <= 0:
            raise ValueError("Universe ID 0'dan büyük olmalıdır.")
        return universe_id

    def game_info(self, universe_id: int) -> Optional[dict]:
        response = self.session.get(
            ROBLOX_GAMES_API,
            params={"universeIds": universe_id},
            timeout=self.timeout,
        )
        response.raise_for_status()
        data = response.json().get("data", [])
        return data[0] if data else None


class Menu:
    def __init__(self) -> None:
        self.accounts = AccountManager()
        self.api = RobloxPublicAPI()

    @staticmethod
    def banner() -> None:
        print(Fore.CYAN + r"""
   ███████╗ █████╗ ███████╗
   ██╔════╝██╔══██╗██╔════╝
   ███████╗███████║█████╗
   ╚════██║██╔══██║██╔══╝
   ███████║██║  ██║██║
   ╚══════╝╚═╝  ╚═╝╚═╝
        SAE AUTO SCRIPT 2.0
""")

    def game_lookup(self) -> None:
        value = input("Universe ID: ").strip()
        try:
            universe_id = self.api.validate_universe_id(value)
            info = self.api.game_info(universe_id)
            if not info:
                print(Fore.YELLOW + "Oyun bulunamadı.")
                return
            print(Fore.GREEN + f"\nAd: {info.get('name', 'Bilinmiyor')}")
            print(f"Universe ID: {info.get('id', universe_id)}")
            print(f"Açıklama: {info.get('description') or '-'}")
            print(f"Oyuncular: {info.get('playing', 0):,}")
            print(f"Ziyaret: {info.get('visits', 0):,}")
            print(f"Güncelleme: {info.get('updated', '-')}")
        except ValueError as exc:
            print(Fore.RED + f"Geçersiz ID: {exc}")
        except requests.RequestException as exc:
            print(Fore.RED + f"Roblox API hatası: {exc}")
        except (OSError, json.JSONDecodeError) as exc:
            print(Fore.RED + f"Veri hatası: {exc}")

    def run(self) -> None:
        while True:
            print("\n" + "=" * 64)
            print(Fore.CYAN + "SAE AUTO SCRIPT")
            print("1. Kullanıcı ekle")
            print("2. Kullanıcıları listele")
            print("3. Kullanıcı sil")
            print("4. Roblox oyun bilgisi getir")
            print("5. Çıkış")
            print("=" * 64)
            choice = input("Seçiminiz: ").strip()
            try:
                if choice == "1":
                    username = input("Roblox kullanıcı adı: ")
                    notes = input("Not (opsiyonel): ")
                    self.accounts.add(username, notes)
                elif choice == "2":
                    self.accounts.list_accounts()
                elif choice == "3":
                    self.accounts.remove(input("Silinecek kullanıcı adı: "))
                elif choice == "4":
                    self.game_lookup()
                elif choice == "5":
                    print(Fore.YELLOW + "Çıkış yapılıyor...")
                    return
                else:
                    print(Fore.RED + "Geçersiz seçim.")
            except KeyboardInterrupt:
                print("\n" + Fore.YELLOW + "İşlem iptal edildi.")
            except Exception as exc:
                logging.exception("Beklenmeyen hata")
                print(Fore.RED + f"Beklenmeyen hata: {exc}")


def main() -> int:
    setup_logging()
    try:
        menu = Menu()
        menu.banner()
        menu.run()
        return 0
    except RuntimeError as exc:
        print(Fore.RED + str(exc))
        return 1
    except KeyboardInterrupt:
        print("\nÇıkış.")
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
