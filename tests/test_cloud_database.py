import os
import unittest
from unittest.mock import patch, MagicMock

from database import get_db_connection
from cloud_database import get_cloud_connection


class CloudDatabaseTests(unittest.TestCase):

    @patch("cloud_database.get_cloud_connection")
    @patch.dict(
        os.environ,
        {"DB_SECRET_ARN": "test-secret"},
        clear=False
    )
    def test_database_uses_cloud_when_secret_exists(self, mock_cloud):
        get_db_connection()

        mock_cloud.assert_called_once()

    @patch("cloud_database.psycopg.connect")
    @patch("cloud_database.boto3.client")
    @patch.dict(
        os.environ,
        {
            "DB_SECRET_ARN": "test-secret",
            "DB_HOST": "example.rds.amazonaws.com",
            "AWS_REGION": "eu-north-1"
        },
        clear=False
    )
    def test_cloud_connection_reads_secret(
        self, mock_boto_client, mock_connect
    ):
        mock_secrets = MagicMock()
        mock_secrets.get_secret_value.return_value = {
            "SecretString": (
                '{"username": "phishing_app", '
                '"password": "fake-test-password"}'
            )
        }

        mock_boto_client.return_value = mock_secrets

        get_cloud_connection()

        mock_secrets.get_secret_value.assert_called_once_with(
            SecretId="test-secret"
        )

        self.assertEqual(
            mock_connect.call_args.kwargs["user"],
            "phishing_app"
        )

        self.assertEqual(
            mock_connect.call_args.kwargs["sslmode"],
            "require"
        )


if __name__ == "__main__":
    unittest.main()
