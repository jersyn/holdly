CREATE EXTENSION IF NOT EXISTS btree_gist;

-- =========================================================================
-- ORGANIZATION
-- =========================================================================
CREATE TABLE organization (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name          text        NOT NULL,
    logo          text,
    description   text,
    contact_info  text,
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now()
);

-- =========================================================================
-- USER
-- =========================================================================
CREATE TABLE "user" (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name      text        NOT NULL,
    last_name       text        NOT NULL,
    email           text        NOT NULL,
    password_hash   text        NOT NULL,
    phone           text,
    role            text        NOT NULL DEFAULT 'CLIENT'
                        CHECK (role IN ('CLIENT', 'ADMIN')),
    organization_id uuid        REFERENCES organization (id) ON DELETE SET NULL,
    registered_at   timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_user_email ON "user" (email);
CREATE INDEX idx_user_organization ON "user" (organization_id);

-- =========================================================================
-- PLACE
-- =========================================================================
CREATE TABLE place (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id uuid    NOT NULL REFERENCES organization (id) ON DELETE CASCADE,
    name            text    NOT NULL,
    description     text,
    images          jsonb,
    capacity        int     NOT NULL CHECK (capacity > 0),
    status          text    NOT NULL DEFAULT 'ACTIVE'
                        CHECK (status IN ('ACTIVE', 'INACTIVE')),
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_place_organization ON place (organization_id);
CREATE INDEX idx_place_status ON place (status);

-- =========================================================================
-- RESERVATION
-- =========================================================================
CREATE TABLE reservation (
    id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id   uuid        NOT NULL REFERENCES "user" (id) ON DELETE CASCADE,
    place_id    uuid        NOT NULL REFERENCES place (id) ON DELETE CASCADE,
    date        date        NOT NULL,
    start_time  time        NOT NULL,
    end_time    time        NOT NULL,
    status      text        NOT NULL DEFAULT 'CONFIRMED'
                    CHECK (status IN ('CONFIRMED', 'CANCELLED')),
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now(),

    CHECK (start_time < end_time),

    EXCLUDE USING gist (
        place_id WITH =,
        int4range(
            EXTRACT(HOUR FROM start_time) * 60 + EXTRACT(MINUTE FROM start_time),
            CASE WHEN end_time = '00:00:00'::time THEN 1440
                 ELSE EXTRACT(HOUR FROM end_time) * 60 + EXTRACT(MINUTE FROM end_time)
            END,
            '[)'
        ) WITH &&
    ) WHERE (status = 'CONFIRMED')
);

CREATE INDEX idx_reservation_client ON reservation (client_id);
CREATE INDEX idx_reservation_place_date ON reservation (place_id, date);
CREATE INDEX idx_reservation_status ON reservation (status);

-- =========================================================================
-- BLOCKED SLOT
-- =========================================================================
CREATE TABLE blocked_slot (
    id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    place_id    uuid        NOT NULL REFERENCES place (id) ON DELETE CASCADE,
    date        date        NOT NULL,
    start_time  time        NOT NULL,
    end_time    time        NOT NULL,
    reason      text,
    created_at  timestamptz NOT NULL DEFAULT now(),

    CHECK (start_time < end_time),

    EXCLUDE USING gist (
        place_id WITH =,
        int4range(
            EXTRACT(HOUR FROM start_time) * 60 + EXTRACT(MINUTE FROM start_time),
            CASE WHEN end_time = '00:00:00'::time THEN 1440
                 ELSE EXTRACT(HOUR FROM end_time) * 60 + EXTRACT(MINUTE FROM end_time)
            END,
            '[)'
        ) WITH &&
    )
);

CREATE INDEX idx_blocked_slot_place_date ON blocked_slot (place_id, date);

-- =========================================================================
-- PAYMENT
-- =========================================================================
CREATE TABLE payment (
    id                    uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    reservation_id        uuid        NOT NULL REFERENCES reservation (id) ON DELETE CASCADE,
    provider              text        NOT NULL DEFAULT 'STRIPE',
    provider_payment_id   text,
    amount                numeric(12, 2) NOT NULL CHECK (amount >= 0),
    currency              text        NOT NULL DEFAULT 'USD',
    status                text        NOT NULL DEFAULT 'PENDING'
                              CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED', 'REFUNDED')),
    created_at            timestamptz NOT NULL DEFAULT now(),
    paid_at               timestamptz
);

CREATE UNIQUE INDEX idx_payment_reservation ON payment (reservation_id);
CREATE INDEX idx_payment_status ON payment (status);

-- =========================================================================
-- REVIEW
-- =========================================================================
CREATE TABLE review (
    id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id   uuid        NOT NULL REFERENCES "user" (id) ON DELETE CASCADE,
    place_id    uuid        NOT NULL REFERENCES place (id) ON DELETE CASCADE,
    rating      int         NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment     text,
    created_at  timestamptz NOT NULL DEFAULT now(),

    UNIQUE (client_id, place_id)
);

CREATE INDEX idx_review_client ON review (client_id);
CREATE INDEX idx_review_place ON review (place_id);

-- =========================================================================
-- NOTIFICATION
-- =========================================================================
CREATE TABLE notification (
    id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         uuid        NOT NULL REFERENCES "user" (id) ON DELETE CASCADE,
    reservation_id  uuid        REFERENCES reservation (id) ON DELETE SET NULL,
    type            text        NOT NULL
                        CHECK (type IN ('NEW_RESERVATION', 'UPCOMING_RESERVATION')),
    message         text        NOT NULL,
    read            boolean     NOT NULL DEFAULT false,
    created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_notification_user ON notification (user_id);
CREATE INDEX idx_notification_reservation ON notification (reservation_id);
