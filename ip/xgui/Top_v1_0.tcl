# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "ARRAY_BASE_ADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "COL_LENGTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DATA_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "REG_DEPTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "ROW_LENGTH" -parent ${Page_0}


}

proc update_PARAM_VALUE.ARRAY_BASE_ADDR { PARAM_VALUE.ARRAY_BASE_ADDR } {
	# Procedure called to update ARRAY_BASE_ADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ARRAY_BASE_ADDR { PARAM_VALUE.ARRAY_BASE_ADDR } {
	# Procedure called to validate ARRAY_BASE_ADDR
	return true
}

proc update_PARAM_VALUE.COL_LENGTH { PARAM_VALUE.COL_LENGTH } {
	# Procedure called to update COL_LENGTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.COL_LENGTH { PARAM_VALUE.COL_LENGTH } {
	# Procedure called to validate COL_LENGTH
	return true
}

proc update_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to update DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to validate DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.REG_DEPTH { PARAM_VALUE.REG_DEPTH } {
	# Procedure called to update REG_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.REG_DEPTH { PARAM_VALUE.REG_DEPTH } {
	# Procedure called to validate REG_DEPTH
	return true
}

proc update_PARAM_VALUE.ROW_LENGTH { PARAM_VALUE.ROW_LENGTH } {
	# Procedure called to update ROW_LENGTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ROW_LENGTH { PARAM_VALUE.ROW_LENGTH } {
	# Procedure called to validate ROW_LENGTH
	return true
}


proc update_MODELPARAM_VALUE.DATA_WIDTH { MODELPARAM_VALUE.DATA_WIDTH PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_WIDTH}] ${MODELPARAM_VALUE.DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.REG_DEPTH { MODELPARAM_VALUE.REG_DEPTH PARAM_VALUE.REG_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.REG_DEPTH}] ${MODELPARAM_VALUE.REG_DEPTH}
}

proc update_MODELPARAM_VALUE.ARRAY_BASE_ADDR { MODELPARAM_VALUE.ARRAY_BASE_ADDR PARAM_VALUE.ARRAY_BASE_ADDR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ARRAY_BASE_ADDR}] ${MODELPARAM_VALUE.ARRAY_BASE_ADDR}
}

proc update_MODELPARAM_VALUE.ROW_LENGTH { MODELPARAM_VALUE.ROW_LENGTH PARAM_VALUE.ROW_LENGTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ROW_LENGTH}] ${MODELPARAM_VALUE.ROW_LENGTH}
}

proc update_MODELPARAM_VALUE.COL_LENGTH { MODELPARAM_VALUE.COL_LENGTH PARAM_VALUE.COL_LENGTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.COL_LENGTH}] ${MODELPARAM_VALUE.COL_LENGTH}
}

