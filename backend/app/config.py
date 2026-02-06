from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "postgresql+asyncpg://localhost:5432/period_tracker"
    api_key: str = "dev-key"

    model_config = {"env_file": ".env"}


settings = Settings()
