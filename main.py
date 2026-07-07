import sys


def main() -> None:
    version = sys.version_info
    print(f"Hello from Python {version.major}.{version.minor}.{version.micro}!")


if __name__ == "__main__":
    main()
