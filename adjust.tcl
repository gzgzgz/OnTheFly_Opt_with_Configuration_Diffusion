
set critical_dist 2.0
set heavy_atom [atomselect top "name Pb Cl I"]
set heavy_list [$heavy_atom get index]
foreach single_atom $heavy_list {
	set getout 0
	while {$getout == 0} {
	set link_hydrogen [atomselect top "(name H) and (within $critical_dist of index $single_atom)"]
	set hydrogen_list [$link_hydrogen get index]
	puts $hydrogen_list
	if { $hydrogen_list != {} } {
		set single_hydrogen [lindex $hydrogen_list 0] 
		set heavy_sel [atomselect top "index $single_atom"]
		set hydro_sel [atomselect top "index $single_hydrogen"]
		set heavy_coord [lindex [$heavy_sel get {x y z}] 0]
		set hydro_coord [lindex [$hydro_sel get {x y z}] 0]
		set direct_vec [vecnorm [vecsub $heavy_coord $hydro_coord]]
		set direct_vec [vecscale $direct_vec [expr $critical_dist + 0.1] ]
		set heavy_coord [vecadd $direct_vec $hydro_coord]
		set mm {}
		lappend mm $heavy_coord
		$heavy_sel set {x y z} $mm
	} else {
		set getout 1
	}
	}
}

set sel_C [atomselect top "name C"]
set C_idx [$sel_C get index]
foreach indiv_C_idx $C_idx {
	set current_C_sel [atomselect top "index $indiv_C_idx"]
	set neighbor_N [atomselect top "(name N) and (within 3 of index $indiv_C_idx)"]
	set neighbor_size [llength [$neighbor_N get index]]
	set die_number [expr rand()]
	if { $neighbor_size == 1 && $die_number > 0.5} {
		set N_coord [lindex [$neighbor_N get {x y z}] 0]
		set C_coord [lindex [$current_C_sel get {x y z}] 0]
		set tmp_swap {}
		lappend tmp_swap $N_coord
		$current_C_sel set {x y z} $tmp_swap
		set tmp_swap {}
		lappend tmp_swap $C_coord
		$neighbor_N set {x y z}  $tmp_swap
	}
}

set sel [atomselect top all]
$sel writexyz adjusted.xyz
