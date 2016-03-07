#/bin/env python

import diamond.collector
import os
import csv
import time


class LoadCollector(diamond.collector.Collector):
    def __init__(self, *args, **kwargs):
        """
        Create a new instance of the LoadCollector class
        """
        # Initialize base Class
        super(LoadCollector, self).__init__(*args, **kwargs)
        self.successful_registers = 0
        self.failed_registers = 0
        self.successful_calls = 0
        self.failed_calls = 0

    def collect(self):
        stats_directory = "/etc/load"
        start_time = time.time() - float(self.config['interval'])

        # Find the files that correspond to registration statistics, modified since last collection
        reg_stats_files = [os.path.join(stats_directory, fn)
                           for fn in os.listdir(stats_directory)
                           if (fn.startswith("auth_reg_client_") and fn.endswith(".csv") and
                               os.path.getmtime(os.path.join(stats_directory, fn)) > start_time)]

        # For each file, most recent first, publish the stats that we care about.
        for reg_stats_file in reg_stats_files:
            with open(reg_stats_file) as csv_file:
                # Each CSV file is a table where the headers are the 0th row, and each subsequent
                # row is the status at a particular time.
                csv_reader = csv.reader(csv_file, delimiter=";")
                title_row = csv_reader.next()

                # Get stats from all remaining rows
                for row in csv_reader:
                    # Get the time of the log. This is in the format:
                    # 2016-02-15\t14:57:24.030256\t1455548244.030256
                    log_time = float(row[title_row.index("CurrentTime")].split("\t")[2])

                    # We publish the rows that were logged in this time period.
                    if log_time > start_time:
                        self.successful_registers += int(row[title_row.index("SuccessfulCall(P)")])
                        self.failed_registers = +int(row[title_row.index("FailedCall(P)")])

        total_registers = self.successful_registers + self.failed_registers
        self.publish_counter("registers.total", total_registers)
        self.publish_counter("registers.failed", self.failed_registers)

        # Now do the same for calls
        call_stats_files = [os.path.join(stats_directory, fn)
                            for fn in os.listdir(stats_directory)
                            if (fn.startswith("media_uac_") and fn.endswith(".csv") and
                                os.path.getmtime(os.path.join(stats_directory, fn)) > start_time)]

        # For each file, most recent first, publish the stats that we care about.
        for call_stats_file in call_stats_files:
            with open(call_stats_file) as csv_file:
                # Each CSV file is a table where the headers are the 0th row, and each subsequent
                # row is the status at a particular time.
                csv_reader = csv.reader(csv_file, delimiter=";")
                title_row = csv_reader.next()

                # Get stats from all remaining rows
                for row in csv_reader:
                    # Get the time of the log. This is in the format:
                    # 2016-02-15\t14:57:24.030256\t1455548244.030256
                    log_time = float(row[title_row.index("CurrentTime")].split("\t")[2])

                    # We publish the rows that were logged in this time period.
                    if log_time > start_time:
                        self.successful_calls += int(row[title_row.index("SuccessfulCall(P)")])
                        self.failed_calls += int(row[title_row.index("FailedCall(P)")])

        # Feels like these should be counters, not gauges, but we're not keeping track of the
        # cumulative value, so just use a gauge.
        total_calls = self.successful_calls + self.failed_calls
        self.publish_counter("calls.total", total_calls)
        self.publish_counter("calls.failed", self.failed_calls)
