package com.civicconnect.config;

import org.springframework.amqp.core.*;
import org.springframework.amqp.rabbit.config.SimpleRabbitListenerContainerFactory;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * RabbitMQ topology for CivicConnect.
 *
 * <p>Exchange strategy: one topic exchange {@code civicconnect.events}.
 * Routing key pattern: {@code <module>.<event>}
 * e.g. {@code issue.submitted}, {@code issue.status_changed}, {@code sla.breached}
 *
 * <p>Dead-letter exchange ({@code civicconnect.dlx}) handles failed messages
 * after max-retry exhaustion.
 */
@Configuration
public class RabbitMQConfig {

    // ── Exchange names ──────────────────────────────────────────────
    public static final String EVENTS_EXCHANGE     = "civicconnect.events";
    public static final String DLX_EXCHANGE        = "civicconnect.dlx";

    // ── Queue names ─────────────────────────────────────────────────
    public static final String NOTIFICATION_QUEUE  = "civicconnect.notifications";
    public static final String AUDIT_QUEUE         = "civicconnect.audit";
    public static final String SLA_MONITOR_QUEUE   = "civicconnect.sla";
    public static final String DLQ                 = "civicconnect.dlq";

    // ── Routing keys ────────────────────────────────────────────────
    public static final String RK_ISSUE_ALL        = "issue.#";
    public static final String RK_SLA_ALL          = "sla.#";
    public static final String RK_AUDIT_ALL        = "audit.#";

    // ── Exchanges ───────────────────────────────────────────────────

    @Bean
    public TopicExchange eventsExchange() {
        return ExchangeBuilder.topicExchange(EVENTS_EXCHANGE).durable(true).build();
    }

    @Bean
    public DirectExchange deadLetterExchange() {
        return ExchangeBuilder.directExchange(DLX_EXCHANGE).durable(true).build();
    }

    // ── Queues ──────────────────────────────────────────────────────

    @Bean
    public Queue notificationQueue() {
        return QueueBuilder.durable(NOTIFICATION_QUEUE)
            .withArgument("x-dead-letter-exchange", DLX_EXCHANGE)
            .withArgument("x-dead-letter-routing-key", "dlq")
            .build();
    }

    @Bean
    public Queue auditQueue() {
        return QueueBuilder.durable(AUDIT_QUEUE)
            .withArgument("x-dead-letter-exchange", DLX_EXCHANGE)
            .withArgument("x-dead-letter-routing-key", "dlq")
            .build();
    }

    @Bean
    public Queue slaMonitorQueue() {
        return QueueBuilder.durable(SLA_MONITOR_QUEUE)
            .withArgument("x-dead-letter-exchange", DLX_EXCHANGE)
            .withArgument("x-dead-letter-routing-key", "dlq")
            .build();
    }

    @Bean
    public Queue deadLetterQueue() {
        return QueueBuilder.durable(DLQ).build();
    }

    // ── Bindings ────────────────────────────────────────────────────

    @Bean
    public Binding notificationBinding() {
        return BindingBuilder.bind(notificationQueue())
            .to(eventsExchange()).with(RK_ISSUE_ALL);
    }

    @Bean
    public Binding auditBinding() {
        return BindingBuilder.bind(auditQueue())
            .to(eventsExchange()).with(RK_AUDIT_ALL);
    }

    @Bean
    public Binding slaBinding() {
        return BindingBuilder.bind(slaMonitorQueue())
            .to(eventsExchange()).with(RK_SLA_ALL);
    }

    @Bean
    public Binding dlqBinding() {
        return BindingBuilder.bind(deadLetterQueue())
            .to(deadLetterExchange()).with("dlq");
    }

    // ── Serialization ────────────────────────────────────────────────

    @Bean
    public MessageConverter messageConverter() {
        return new Jackson2JsonMessageConverter();
    }

    @Bean
    public RabbitTemplate rabbitTemplate(ConnectionFactory connectionFactory) {
        RabbitTemplate template = new RabbitTemplate(connectionFactory);
        template.setMessageConverter(messageConverter());
        template.setMandatory(true);
        return template;
    }

    @Bean
    public SimpleRabbitListenerContainerFactory rabbitListenerContainerFactory(
            ConnectionFactory connectionFactory) {
        SimpleRabbitListenerContainerFactory factory = new SimpleRabbitListenerContainerFactory();
        factory.setConnectionFactory(connectionFactory);
        factory.setMessageConverter(messageConverter());
        factory.setDefaultRequeueRejected(false);
        return factory;
    }
}
