use persistence_ready_20Nov2016.dta, clear
xtmelogit in_sn_numerator is_ap##c.inFUds is_ap##c.inTXds is_ja##c.inFUds is_ja##c.inTXds is_sn##c.inFUds is_sn##c.inTXds days_since if  in_sn_denom || ru: || provid:

THIS IS SOMETHING NEW jjjjj