import json
import unittest
from unittest.mock import MagicMock, patch

from cache import analyze_email_with_cache


class TestRedisCache(unittest.TestCase):

    @patch("cache.analyze_email")
    @patch("cache.get_redis_client")
    def test_cache_hit(self, mock_client, mock_analyze):
        cached_result = {
            "score": 80,
            "risk_level": "High",
            "indicators_count": 8
        }

        redis_client = MagicMock()
        redis_client.get.return_value = json.dumps(cached_result)
        mock_client.return_value = redis_client

        result = analyze_email_with_cache("test email")

        self.assertEqual(result, cached_result)
        mock_analyze.assert_not_called()

    @patch("cache.analyze_email")
    @patch("cache.get_redis_client")
    def test_cache_miss(self, mock_client, mock_analyze):
        redis_client = MagicMock()
        redis_client.get.return_value = None
        mock_client.return_value = redis_client

        mock_analyze.return_value = {"score": 0}

        result = analyze_email_with_cache("test email")

        self.assertEqual(result["score"], 0)
        mock_analyze.assert_called_once_with("test email")
        redis_client.setex.assert_called_once()

    @patch("cache.analyze_email")
    @patch("cache.get_redis_client", return_value=None)
    def test_redis_not_configured(self, mock_client, mock_analyze):
        mock_analyze.return_value = {"score": 0}

        result = analyze_email_with_cache("test email")

        self.assertEqual(result["score"], 0)
        mock_analyze.assert_called_once()


if __name__ == "__main__":
    unittest.main()
