import os

from pydantic import model_validator
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "postgresql+asyncpg://localhost:5432/period_tracker"
    api_key: str = "dev-key"
    demo_api_key: str | None = None

    model_config = {"env_file": ".env"}

    @model_validator(mode="after")
    def fix_database_url(self):
        # Railway provides postgresql:// but asyncpg needs postgresql+asyncpg://
        if self.database_url.startswith("postgresql://"):
            self.database_url = self.database_url.replace(
                "postgresql://", "postgresql+asyncpg://", 1
            )
        return self

    @model_validator(mode="after")
    def demo_key_must_differ(self):
        if self.demo_api_key is not None and self.demo_api_key == self.api_key:
            raise ValueError("DEMO_API_KEY must differ from API_KEY")
        return self

    @model_validator(mode="after")
    def reject_default_api_key_in_production(self):
        if self.api_key == "dev-key" and os.getenv("RAILWAY_ENVIRONMENT"):
            raise ValueError(
                "API_KEY must be set to a secure value in production "
                "(still using default 'dev-key')"
            )
        return self


settings = Settings()
