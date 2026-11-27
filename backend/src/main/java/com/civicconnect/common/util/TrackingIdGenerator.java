package com.civicconnect.common.util;

import org.springframework.stereotype.Component;

import java.time.Year;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Generates human-readable issue tracking IDs in the format {@code CC-YYYY-NNNNN}.
 *
 * <p>The counter is in-memory and resets on restart. For production, the counter
 * should be backed by a Redis INCR or a PostgreSQL sequence per municipality.
 * The database also enforces uniqueness via the {@code tracking_id} UNIQUE constraint.
 *
 * <p>Example: {@code CC-2024-00142}
 */
@Component
public class TrackingIdGenerator {

    private final AtomicLong counter = new AtomicLong(1);

    public String generate() {
        int  year = Year.now().getValue();
        long seq  = counter.getAndIncrement();
        return String.format("CC-%d-%05d", year, seq);
    }
}
