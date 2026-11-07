import hashlib
import json
import logging
import os

import redis

from detector import analyze_email

logger = logging.getLogger(__name__)

# Cache scan results for one hour.
CACHE_TTL_SECONDS = 3600


def get_redis_client():
    """Create a Redis connection using the environment configuration."""
    redis_url = os.getenv("REDIS_URL")

    if not redis_url:
        return None

    return redis.Redis.from_url(
        redis_url,
        socket_connect_timeout=2,
        socket_timeout=2,
        decode_responses=True
    )


def analyze_email_with_cache(email_content):
    """Return a cached analysis when available, otherwise analyze the email."""
    client = None

    # Hash the email content to create a fixed-length cache key.
    content_hash = hashlib.sha256(
        email_content.encode("utf-8")
    ).hexdigest()

    cache_key = f"phishing:scan:v1:{content_hash}"

    try:
        client = get_redis_client()

        if client is not None:
            cached_result = client.get(cache_key)

            if cached_result is not None:
                logger.info("Phishing analysis cache hit")
                return json.loads(cached_result)

    except (redis.RedisError, ValueError, TypeError):
        logger.warning("Redis unavailable; analyzing email normally.")

    # Preserve the existing detection behavior.
    result = analyze_email(email_content)

    if client is not None:
        try:
            client.setex(
                cache_key,
                CACHE_TTL_SECONDS,
                json.dumps(result)
            )
        except redis.RedisError:
            logger.warning("Could not store phishing analysis in Redis.")

    return result
