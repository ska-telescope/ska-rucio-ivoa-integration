import pytest
import requests
import logging

# Configure logging
logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

def test_youcat_availability():
    """Test the youcat availability endpoint"""

    url = "http://youcat:8080/youcat/availability"
    headers = {"accept": "application/xml"}

    logger.info("Calling availability endpoint")
    logger.info("URL: %s", url)
    logger.info("Headers: %s", headers)

    response = requests.get(url, headers=headers)

    logger.info("Response code: %s", response.status_code)
    logger.info("Response headers:")
    for header, value in response.headers.items():
        logger.info("%s: %s", header, value)

    response_text = response.text
    logger.info("Response text: %s", response_text)

    expected_availability = "service is accepting queries"
    assert expected_availability in response_text, f"expected_availability should be {expected_availability}"
    logger.info("Youcat availability passed")
