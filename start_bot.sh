#!/bin/bash

perl bot2.pl --tg_key '123:abc' --use_mutex --city your_city 2>&1 | tee -a /tmp/beta_decoder_bot.log
