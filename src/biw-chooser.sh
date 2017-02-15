##
# BIW-CHOOSER - Scrollable Chooser Widget
# Copyright 2017 by Chad Juliano
# 
# Licensed under GNU Lesser General Public License v3.0 only. Some rights
# reserved. See LICENSE.
##

# Indexes
declare -i choose_idx_active=0
declare -i choose_idx_last

# Data
declare -a choose_data_values
declare -i choose_data_size

# Layout
declare -ri choose_margin=10
declare -ri choose_width=50
declare -ri choose_height_max=6
declare -i choose_height

# Colors
declare -ri choose_color_text=$color_black
declare -ri choose_color_active=$color_red
declare -ri choose_color_inactive=$color_blue
declare -ri choose_color_slider_bar=$color_cyan
declare -ri choose_color_handle=$color_yellow


function fn_choose_init()
{
	# get refrence to array with menu entries
	choose_data_values=("${!1}")
	choose_data_size=${#choose_data_values[*]}
	choose_idx_last=$((choose_data_size - 1))

	# menu dimensions
	choose_height=$((choose_data_size > choose_height_max \
		? choose_height_max : choose_data_size))
}

function fn_choose_router()
{
	local -r _event=$1

	case $_event in
		$biw_event_show)
			fn_choose_show
			;;
		$biw_event_up)
			fn_choose_up
			;;
		$biw_event_down)
			fn_choose_down
			;;
		*)
			echo "Event not found: ${_event}"
			exit 1
			;;
	esac
}

function fn_choose_show()
{
	# set window location and redraw
	fn_choose_move_window $choose_idx_active
}

function fn_choose_cursor_home()
{
	# position the cursor at the start of the menu
	fn_esc $esc_restore_cursor
	fn_csi $csi_row_up $choose_height
}

function fn_choose_redraw()
{
	# move to the top of where we will draw the menu
	fn_choose_cursor_home

	# calculate indexes to draw
	local _indexes=$(eval echo {$_choose_idx_start..$_choose_idx_end})

	# draw all menu items
	for _line_idx in ${_indexes}
	do
		fn_choose_draw_row $_line_idx
		fn_csi $csi_row_down 1
	done

	# set the cursor after the active item
	fn_csi $csi_row_up $((_choose_idx_end - choose_idx_active + 1))
}

function fn_choose_draw_row()
{
	local -i _line_idx=$1

	# skip past margin
	fn_csi $csi_col_pos $choose_margin

	# set text color (BG will be set later)
	fn_csi $csi_set_color $((color_fg + choose_color_text))

	fn_choose_draw_selection $_line_idx
	fn_choose_draw_slider $_line_idx

	# reset colors
	fn_csi $csi_set_color 0
}

function fn_choose_draw_slider()
{
	local -i _line_idx=$1
	local _last_char=$decg_hz_line

	if ((_line_idx == _choose_idx_start))
	then
		# Top charachter
		if ((_line_idx == 0))
		then
			_last_char=$decg_t_top
		else
			_last_char='^'
		fi
	elif ((_line_idx == _choose_idx_end))
	then
		# Bottom Charachter
		if ((_line_idx == choose_idx_last))
		then
			_last_char=$decg_t_bottom
		else
			_last_char='v'
		fi
	fi

	local -i _slider_color=$choose_color_slider_bar

	if ((choose_idx_active == _line_idx))
	then
		_slider_color=$choose_color_handle
	fi

	fn_csi $csi_set_color $((color_bg + _slider_color))
	echo -en "${_last_char}"
}

function fn_choose_draw_selection()
{
	local -i _line_idx=$1
	local -i _panel_color=$choose_color_inactive

	if ((choose_idx_active == _line_idx))
	then
		_panel_color=$choose_color_active
	fi

	# get line data from array
	local _line_result="${choose_data_values[$_line_idx]}"

	# selection contents
	_line_result="[${_line_idx}] ${_line_result}"

	# pad and trim line
	printf -v _line_result "%-${choose_width}s" "${_line_result}"
	_line_result="${_line_result:0:${choose_width}}"

	# output line
	fn_csi $csi_set_color $((color_bg + _panel_color))
	echo -n "${_line_result}"
}

function fn_choose_move_window()
{
	# location is specified by the start
	_choose_idx_start=$1

	# end is calculateed
	_choose_idx_end=$((_choose_idx_start + choose_height - 1))

	fn_choose_redraw
}

function fn_choose_down()
{
	if ((choose_idx_active >= choose_idx_last))
	then
		# we are at the end of the data so we can't move
		return
	fi

	# move active index
	((choose_idx_active += 1))

	if ((choose_idx_active > _choose_idx_end))
	then
		# new index has exceeded the bounds of the window
		fn_choose_move_window $((_choose_idx_start + 1))
		return
	fi

	# new index is inside the current window and so we just
	# move the active item down
	fn_choose_draw_row $((choose_idx_active - 1))
	fn_csi $csi_row_down 1
	fn_choose_draw_row $choose_idx_active
}

function fn_choose_up()
{
	if ((choose_idx_active <= 0))
	then
		# we are at the start of the data so we can't move
		return
	fi

	# move active index
	((choose_idx_active -= 1))

	if ((choose_idx_active < _choose_idx_start))
	then
		# new index has exceeded the bounds of the window
		fn_choose_move_window $((_choose_idx_start - 1))
		return
	fi

	# new index is inside the current window and so we just
	# move the active item up
	fn_choose_draw_row $((choose_idx_active + 1))
	fn_csi $csi_row_up 1
	fn_choose_draw_row $choose_idx_active
}
