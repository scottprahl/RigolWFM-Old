meta:
  id: wfm1000e
  title: Rigol DS1102E oscilloscope waveform file format
  file-extension: wfm
  endian: le

doc: |
  Rigol DS1102E scope .wmf format abstracted from a python script

instances:
  header:
    pos: 0
    type: header
  data:
    type: raw_data

types:
  header:
    seq:
      - id: magic
        contents: [0xa5,0xa5,0x00,0x00]
      - id: blank_12
        contents: [0,0,0,0,0,0,0,0,0,0,0,0]
      - id: adc_mode
        type: u1
      - id: padding_2
        contents: [0x00,0x00,0x00]
      - id: roll_stop
        type: u4
      - id: unused_4
        contents: [0x00,0x00,0x00,0x00]
      - id: ch1_points
        type: u4
      - id: active_channel
        type: u1
      - id: padding_3
        contents: [0x00,0x00,0x00]
      - id: ch1
        type: channel_header
      - id: padding_4
        contents: [0x00,0x00]
      - id: ch2
        type: channel_header
      - id: time_delay
        type: u1
      - id: padding_5
        contents: [0x00]
      - id: time1
        type: time_header
      - id: logic
        type: logic_analyzer_header
      - id: trigger_mode
        type: u1
        enum: trigger_mode_enum
      - id: trigger1
        type: trigger_header
      - id: trigger2
        type: trigger_header
      - id: padding_6
        contents: [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]
      - id: ch2_points_tmp
        type: u4
      - id: time2
        type: time_header
      - id: la_sample_rate
        doc: This does not exist in early file formats, unsure how to detect if missing
        type: f4
        repeat: expr
        repeat-expr: 1
    instances:
      ch2_points:
        value: "_root.header.ch2.enabled and _root.header.ch2_points_tmp == 0 ? 
                _root.header.ch1_points :
                _root.header.ch2_points_tmp"
        doc: Use ch1_points when ch2_points is not written

      ch1_volt_scale:
        value: '_root.header.ch1.invert_m ?
                -4e-8 * _root.header.ch1.scale_m * _root.header.ch1.probe:
                +4e-8 * _root.header.ch1.scale_m * _root.header.ch1.probe'
      ch1_volt_shift:
        value: _root.header.ch1.shift_m * _root.header.ch1_volt_scale
      ch1_volt_length:
        value: _root.header.ch1_points - _root.header.roll_stop
        doc: In rolling mode, not all samples are valid otherwise use all samples

      ch2_volt_scale:
        value: '_root.header.ch2.invert_m ?
                -4e-8 * _root.header.ch2.scale_m * _root.header.ch2.probe:
                +4e-8 * _root.header.ch2.scale_m * _root.header.ch2.probe'
      ch2_volt_shift:
        value: _root.header.ch2.shift_m * _root.header.ch2_volt_scale
      ch2_volt_length:
        value: _root.header.ch2_points - _root.header.roll_stop
        doc: In rolling mode, not all samples are valid otherwise use all samples

      ch1_time_scale:
        value: 1.0 / _root.header.time1.sample_rate
      ch1_time_delay:
        value: 1.0e-12 * _root.header.time1.delay_m
      ch2_time_scale:
        value: "_root.header.trigger_mode == trigger_mode_enum::alt ? 
                 1.0 / _root.header.time2.sample_rate : 
                 _root.header.ch1_time_scale"
      ch2_time_delay:
        value: "_root.header.trigger_mode == trigger_mode_enum::alt ? 
                 1.0e-12 * _root.header.time2.delay_m : 
                 _root.header.ch1_time_delay"

  channel_header:
    seq:
      - id: scale_d
        type: s4
      - id: shift_d
        type: s2
      - id: unknown_1
        type: u2
      - id: probe
        type: f4
      - id: unused_bits_0
        type: b7
      - id: invert_d
        type: b1
      - id: unused_bits_1
        type: b7
      - id: enabled
        type: b1
      - id: unused_bits_2
        type: b7
      - id: invert_m
        type: b1
      - id: unknown_2
        type: u1
      - id: scale_m
        type: s4
      - id: shift_m
        type: s2

  time_header:
    seq:
      - id: scale_d
        type: s8
      - id: delay_d
        type: s8
      - id: sample_rate
        type: f4
      - id: scale_m
        type: s8
      - id: delay_m
        type: s8

  trigger_header:
    seq:
      - id: mode
        type: u1
        enum: trigger_mode_enum
      - id: source
        type: u1
      - id: coupling
        type: u1
      - id: sweep
        type: u1
      - id: padding_1
        contents: [0x00]
      - id: sens
        type: f4
      - id: holdoff
        type: f4
      - id: level
        type: f4
      - id: direct
        type: u1
      - id: pulse_type
        type: u1
      - id: padding_2
        contents: [0x00,0x00]
      - id: pulse_width
        type: f4
      - id: slope_type
        type: u1
      - id: padding_3
        contents: [0x00,0x00,0x00]
      - id: lower
        type: f4
      - id: slope_width
        type: f4
      - id: video_pol
        type: u1
      - id: video_sync
        type: u1
      - id: video_std
        type: u1

  logic_analyzer_header:
    seq:
      - id: unused
        type: b7
      - id: enabled
        type: b1
      - id: active_channel
        doc: Should be 0 to 16
        type: u1
      - id: enabled_channels
        doc: Each bit corresponds to one enabled channel
        type: u2
      - id: position
        size: 16
      - id: group8to15size
        doc: Should be 7-15
        type: u1
      - id: group0to7size
        doc: Should be 7-15
        type: u1

  raw_data:
    seq:
      - id: ch1
        type: s1
        if: _root.header.ch1.enabled
        repeat: expr
        repeat-expr: _root.header.ch1_points

      - id: ch2
        type: s1
        if: _root.header.ch2.enabled
        repeat: expr
        repeat-expr: _root.header.ch2_points
        
      - id: logic
        doc: Not clear where the LA length is stored assume same as ch1_points
        type: u1
        repeat: expr
        repeat-expr: '_root.header.logic.enabled ? _root.header.ch1_points : 0'
        

enums:
  source:
    0 : ch1
    1 : ch2
    2 : ext
    3 : ext5
    5 : ac_line
    7 : dig_ch

  trigger_mode_enum:
    0 : edge
    1 : pulse
    2 : slope
    3 : video
    4 : alt
    5 : pattern
    6 : duration