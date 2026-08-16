from pathlib import Path

from dotenv import load_dotenv


load_dotenv(Path(__file__).with_name(".env"))

from app.main import create_app  # noqa: E402


app = create_app()
