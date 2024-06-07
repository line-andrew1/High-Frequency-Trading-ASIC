# Make file for a Hammer project
TOP_DIR := $(realpath ../../ee477-hammer-cad)
OBJ_DIR := build
INPUT_CFGS := cfg/cfg.yml cfg/src.yml cfg/verification.yml
TB_CFGS := cfg/tb.yml

include $(TOP_DIR)/module_top.mk

