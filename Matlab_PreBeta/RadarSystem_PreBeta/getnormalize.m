function m = getnormalize(m2)

m = (m2-min(min(m2)))./(max(max(m2))-min(min(m2)));

end