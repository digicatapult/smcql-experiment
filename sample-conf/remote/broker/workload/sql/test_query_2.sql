SELECT mineral_id,SUM(mass_delivered)
FROM shipment_content sc JOIN shipments s ON (s.shipment_id = sc.shipment_id)
WHERE (s.site = 4 OR s.site = 7)
GROUP BY mineral_id
