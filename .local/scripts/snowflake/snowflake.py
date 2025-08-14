#!/usr/bin/env python3

import time
import threading

class IdWorker:
    """
    雪花算法 ID 生成器
    """

    def __init__(self, datacenter_id, worker_id):
        """
        :param datacenter_id: 数据中心 ID (0-31)
        :param worker_id: 工作节点 ID (0-31)
        """
        # 起始时间戳，设置为一个固定的时间，用于计算时间差
        self.twepoch = 1288834974657

        # 机器 ID 所占位数
        self.worker_id_bits = 5

        # 数据中心 ID 所占位数
        self.datacenter_id_bits = 5

        # 支持的最大机器 ID
        self.max_worker_id = -1 ^ (-1 << self.worker_id_bits)

        # 支持的最大数据中心 ID
        self.max_datacenter_id = -1 ^ (-1 << self.datacenter_id_bits)

        # 序列号所占位数
        self.sequence_bits = 12

        # 机器 ID 向左移 12 位
        self.worker_id_shift = self.sequence_bits

        # 数据中心 ID 向左移 17 位 (12+5)
        self.datacenter_id_shift = self.sequence_bits + self.worker_id_bits

        # 时间戳向左移 22 位 (5+5+12)
        self.timestamp_left_shift = self.sequence_bits + self.worker_id_bits + self.datacenter_id_bits

        # 生成序列的掩码，这里为 4095 (0b111111111111=0xfff=4095)
        self.sequence_mask = -1 ^ (-1 << self.sequence_bits)

        # 数据中心 ID
        self.datacenter_id = datacenter_id
        if datacenter_id > self.max_datacenter_id or datacenter_id < 0:
            raise ValueError(f"datacenter_id 必须在 0-{self.max_datacenter_id} 之间")

        # 工作节点 ID
        self.worker_id = worker_id
        if worker_id > self.max_worker_id or worker_id < 0:
            raise ValueError(f"worker_id 必须在 0-{self.max_worker_id} 之间")

        # 并发控制
        self.lock = threading.Lock()  # 使用 threading.Lock

        # 毫秒内序列(0~4095)
        self.sequence = 0

        # 上次生成 ID 的时间戳
        self.last_timestamp = -1

    def _gen_timestamp(self):
        """
        生成当前时间戳(毫秒)
        """
        return int(time.time() * 1000)

    def _wait_next_millis(self, last_timestamp):
        """
        阻塞到下一个毫秒，直到获得新的时间戳
        """
        timestamp = self._gen_timestamp()
        while timestamp <= last_timestamp:
            timestamp = self._gen_timestamp()
        return timestamp

    def get_id(self):
        """
        获取新的 ID
        """
        with self.lock:  # 保证并发安全
            timestamp = self._gen_timestamp()

            # 如果当前时间小于上一次 ID 生成的时间戳，说明系统时钟回退过，这时应该抛出异常
            if timestamp < self.last_timestamp:
                raise Exception(
                    f"时钟回退.  拒绝在 {self.last_timestamp} 毫秒内生成 id"
                )

            # 如果是同一时间生成的，则sequence+1
            if self.last_timestamp == timestamp:
                self.sequence = (self.sequence + 1) & self.sequence_mask
                # 毫秒内序列溢出
                if self.sequence == 0:
                    # 阻塞到下一个毫秒,获得新的时间戳
                    timestamp = self._wait_next_millis(self.last_timestamp)
            else:
                # 时间戳改变，毫秒内序列重置
                self.sequence = 0

            # 上次生成 ID 的时间戳
            self.last_timestamp = timestamp

            # 移位并通过或运算拼到一起组成 64 位的 ID
            new_id = (
                ((timestamp - self.twepoch) << self.timestamp_left_shift)
                | (self.datacenter_id << self.datacenter_id_shift)
                | (self.worker_id << self.worker_id_shift)
                | self.sequence
            )

            return new_id


if __name__ == '__main__':
    # 初始化 IdWorker，指定数据中心 ID 和工作节点 ID
    worker = IdWorker(datacenter_id=1, worker_id=1)

    new_id = worker.get_id()
    print(new_id)

