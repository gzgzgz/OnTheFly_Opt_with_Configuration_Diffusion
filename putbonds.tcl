#set nf [molinfo top get numframes]
set sel_pb [atomselect top "name Pb PB"]
set pb_set [$sel_pb get {x y z}]
set sel_I [atomselect top "name I"]
set I_set [$sel_I get {x y z}]
set sel_Cl [atomselect top "name Cl"]
set Cl_set [$sel_Cl get {x y z}]
foreach coord_pb $pb_set {
	draw color red
	foreach coord_I $I_set {
		set pb_I_dist [vecdist $coord_pb $coord_I]
		if { $pb_I_dist < 4.0 } {
			draw cylinder $coord_pb $coord_I radius 0.3 
		}
	}
	draw color green
	foreach coord_Cl $Cl_set {
		set pb_Cl_dist [vecdist $coord_pb $coord_Cl]
		if { $pb_Cl_dist < 3.5 } {
			draw cylinder $coord_pb $coord_Cl radius 0.3
		}
	}
}
