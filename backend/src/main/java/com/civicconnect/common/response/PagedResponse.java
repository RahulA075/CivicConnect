package com.civicconnect.common.response;

import lombok.Getter;
import org.springframework.data.domain.Page;

import java.util.List;

/**
 * Pagination envelope returned by all list endpoints.
 * Wraps Spring Data {@link Page} into a flat, serialisable structure.
 *
 * @param <T> element type
 */
@Getter
public class PagedResponse<T> {

    private final List<T> content;
    private final int     page;
    private final int     size;
    private final long    totalElements;
    private final int     totalPages;
    private final boolean first;
    private final boolean last;

    private PagedResponse(Page<T> page) {
        this.content       = page.getContent();
        this.page          = page.getNumber();
        this.size          = page.getSize();
        this.totalElements = page.getTotalElements();
        this.totalPages    = page.getTotalPages();
        this.first         = page.isFirst();
        this.last          = page.isLast();
    }

    public static <T> PagedResponse<T> of(Page<T> page) {
        return new PagedResponse<>(page);
    }

    public static <T> ApiResponse<PagedResponse<T>> toApiResponse(Page<T> page) {
        return ApiResponse.success(new PagedResponse<>(page));
    }
}
