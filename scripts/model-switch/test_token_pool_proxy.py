#!/usr/bin/env python3
"""
Token Pool Proxy 单元测试
测试用量上报功能
"""

import json
import time
import threading
import unittest
from unittest.mock import patch, MagicMock
import sys
import os

# 添加脚本目录到路径
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, SCRIPT_DIR)

import token_pool_proxy as proxy


class TestUsageReport(unittest.TestCase):
    """测试用量上报功能"""

    def setUp(self):
        """测试前准备"""
        proxy._config = {
            "usage_report": {
                "enabled": True,
                "url": "http://localhost:6040/system/dashboard/token-pool/usage-report",
                "timeout_secs": 5
            }
        }
        proxy._usage_report_queue.clear()

    def tearDown(self):
        """测试后清理"""
        proxy._usage_report_queue.clear()

    def test_parse_usage_from_response_zhipu_format(self):
        """测试解析智谱格式的token用量"""
        resp = {
            "usage": {
                "input_tokens": 1200,
                "output_tokens": 350
            }
        }
        prompt, completion = proxy._parse_usage_from_response(json.dumps(resp).encode(), "anthropic_compat")
        self.assertEqual(prompt, 1200)
        self.assertEqual(completion, 350)

    def test_parse_usage_from_response_openai_format(self):
        """测试解析OpenAI格式的token用量"""
        resp = {
            "usage": {
                "prompt_tokens": 800,
                "completion_tokens": 200
            }
        }
        prompt, completion = proxy._parse_usage_from_response(json.dumps(resp).encode(), "openai_compat")
        self.assertEqual(prompt, 800)
        self.assertEqual(completion, 200)

    def test_parse_usage_from_response_empty(self):
        """测试解析空响应"""
        resp = {}
        prompt, completion = proxy._parse_usage_from_response(json.dumps(resp).encode(), "anthropic_compat")
        self.assertEqual(prompt, 0)
        self.assertEqual(completion, 0)

    def test_parse_usage_from_response_invalid(self):
        """测试解析无效响应"""
        prompt, completion = proxy._parse_usage_from_response(b"invalid json", "anthropic_compat")
        self.assertEqual(prompt, 0)
        self.assertEqual(completion, 0)

    def test_report_usage_disabled(self):
        """测试上报被禁用时不会发送请求"""
        proxy._config["usage_report"]["enabled"] = False

        with patch('urllib.request.urlopen') as mock_urlopen:
            proxy._report_usage_async(
                key_name="test_key",
                model="test_model",
                prompt_tokens=100,
                completion_tokens=50,
                latency_ms=1000,
                status_code=200,
                error_msg=None
            )
            # 等待异步线程完成
            time.sleep(0.1)
            mock_urlopen.assert_not_called()

    def test_report_usage_no_url(self):
        """测试没有配置URL时不会发送请求"""
        proxy._config["usage_report"]["url"] = ""

        with patch('urllib.request.urlopen') as mock_urlopen:
            proxy._report_usage_async(
                key_name="test_key",
                model="test_model",
                prompt_tokens=100,
                completion_tokens=50,
                latency_ms=1000,
                status_code=200,
                error_msg=None
            )
            time.sleep(0.1)
            mock_urlopen.assert_not_called()

    @patch('urllib.request.urlopen')
    def test_report_usage_success(self, mock_urlopen):
        """测试上报成功"""
        mock_response = MagicMock()
        mock_response.status = 200
        mock_urlopen.return_value.__enter__.return_value = mock_response

        proxy._report_usage_async(
            key_name="zhipu_max_1",
            model="glm-5.1",
            prompt_tokens=1200,
            completion_tokens=350,
            latency_ms=2400,
            status_code=200,
            error_msg=None
        )

        # 等待异步线程完成
        time.sleep(0.2)

        # 验证请求被发送
        mock_urlopen.assert_called()
        call_args = mock_urlopen.call_args
        req = call_args[0][0]

        # 验证请求内容
        self.assertEqual(req.full_url, proxy._config["usage_report"]["url"])
        self.assertEqual(req.method, "POST")
        self.assertEqual(req.get_header("Content-type"), "application/json")

        # 验证请求体
        body = json.loads(req.data)
        self.assertEqual(body["key_name"], "zhipu_max_1")
        self.assertEqual(body["model"], "glm-5.1")
        self.assertEqual(body["prompt_tokens"], 1200)
        self.assertEqual(body["completion_tokens"], 350)
        self.assertEqual(body["latency_ms"], 2400)
        self.assertEqual(body["status_code"], 200)
        self.assertIsNone(body["error_msg"])
        self.assertIn("timestamp", body)

    @patch('urllib.request.urlopen')
    def test_report_usage_failure_no_retry_on_success(self, mock_urlopen):
        """测试上报成功不需要重试"""
        mock_response = MagicMock()
        mock_response.status = 200
        mock_urlopen.return_value.__enter__.return_value = mock_response

        proxy._report_usage_async(
            key_name="test_key",
            model="test_model",
            prompt_tokens=100,
            completion_tokens=50,
            latency_ms=1000,
            status_code=200,
            error_msg=None
        )

        time.sleep(0.2)

        # 只应该被调用一次
        self.assertEqual(mock_urlopen.call_count, 1)

    @patch('urllib.request.urlopen')
    def test_report_usage_queue_limit(self, mock_urlopen):
        """测试上报队列满时丢弃最老的"""
        mock_response = MagicMock()
        mock_response.status = 200
        mock_urlopen.return_value.__enter__.return_value = mock_response

        # 快速发送超过队列限制的报告
        for i in range(proxy._MAX_REPORT_QUEUE_SIZE + 10):
            proxy._report_usage_async(
                key_name=f"key_{i}",
                model="test_model",
                prompt_tokens=100,
                completion_tokens=50,
                latency_ms=1000,
                status_code=200,
                error_msg=None
            )

        time.sleep(0.5)

        # 验证队列大小不超过限制
        with proxy._usage_report_lock:
            self.assertLessEqual(len(proxy._usage_report_queue), proxy._MAX_REPORT_QUEUE_SIZE)

    def test_report_usage_error_case(self):
        """测试错误情况的上报"""
        with patch('urllib.request.urlopen') as mock_urlopen:
            mock_response = MagicMock()
            mock_response.status = 200
            mock_urlopen.return_value.__enter__.return_value = mock_response

            proxy._report_usage_async(
                key_name="test_key",
                model="test_model",
                prompt_tokens=0,
                completion_tokens=0,
                latency_ms=5000,
                status_code=429,
                error_msg="Rate limit exceeded"
            )

            time.sleep(0.2)

            # 验证请求被发送
            mock_urlopen.assert_called()
            call_args = mock_urlopen.call_args
            req = call_args[0][0]
            body = json.loads(req.data)

            self.assertEqual(body["status_code"], 429)
            self.assertEqual(body["error_msg"], "Rate limit exceeded")
            self.assertEqual(body["prompt_tokens"], 0)
            self.assertEqual(body["completion_tokens"], 0)


class TestConfigLoading(unittest.TestCase):
    """测试配置加载"""

    def test_config_has_usage_report(self):
        """测试配置文件中包含usage_report节点"""
        keys_file = os.path.join(SCRIPT_DIR, "keys.json")
        with open(keys_file, 'r') as f:
            config = json.load(f)

        self.assertIn("usage_report", config)
        self.assertIn("enabled", config["usage_report"])
        self.assertIn("url", config["usage_report"])
        self.assertIn("timeout_secs", config["usage_report"])

    def test_usage_report_enabled(self):
        """测试usage_report默认启用"""
        keys_file = os.path.join(SCRIPT_DIR, "keys.json")
        with open(keys_file, 'r') as f:
            config = json.load(f)

        self.assertTrue(config["usage_report"]["enabled"])

    def test_usage_report_url_format(self):
        """测试上报URL格式正确"""
        keys_file = os.path.join(SCRIPT_DIR, "keys.json")
        with open(keys_file, 'r') as f:
            config = json.load(f)

        url = config["usage_report"]["url"]
        self.assertTrue(url.startswith("http"))
        self.assertIn("/system/dashboard/token-pool/usage-report", url)


class TestTimestamp(unittest.TestCase):
    """测试时间戳生成"""

    def test_now_returns_datetime(self):
        """测试_now()返回带时区的datetime"""
        now = proxy._now()
        self.assertIsNotNone(now.tzinfo)


if __name__ == "__main__":
    unittest.main(verbosity=2)
