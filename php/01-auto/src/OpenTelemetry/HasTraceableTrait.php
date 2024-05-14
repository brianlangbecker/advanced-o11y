<?php declare(strict_types=1);

namespace App\OpenTelemetry;

use OpenTelemetry\API\Globals;
use OpenTelemetry\Contrib\Otlp\OtlpHttpTransportFactory;
use OpenTelemetry\API\Trace\SpanInterface;
use OpenTelemetry\API\Trace\SpanKind;
use OpenTelemetry\API\Trace\StatusCode;
use OpenTelemetry\API\Trace\TraceInterface;
use OpenTelemetry\API\Trace\Span;
use OpenTelemetry\SDK\Trace\Tracer;
use OpenTelemetry\Context\ContextInterface;
use App\OpenTelemetry\SdkBuilder;


trait HasTraceableTrait
{
    private SdkBuilder $builder;

    private function getTracer(): Tracer
    {
        $this->builder->build();

        $tracerProvider = Globals::tracerProvider();
        return $tracerProvider->getTracer('io.opentelemetry.contrib.php');
    }
    private function createSpan(string $name = null, ?ContextInterface $parent = null): SpanInterface
    {
        if (null === $name) {
            $name = $this::class;
        }
        $tracer = $this->getTracer();
        $spanBuilder = $tracer->spanBuilder($name)
            ->setSpanKind(SpanKind::KIND_SERVER);
        if (null !== $parent) {
            $spanBuilder->setParent($parent);
        }
        return $spanBuilder->startSpan();
    }
    private function setOkStatus(SpanInterface $span): void
    {
        if (!$span instanceof Span) {
            $span->setStatus(StatusCode::STATUS_OK);
            return;
        }
        $spanStatusCode = $span->toSpanData()->getStatus()->getCode();
        if ($spanStatusCode === StatusCode::STATUS_ERROR) {
            // Do not overwriting Error Status
            return;
        }
        $span->setStatus(StatusCode::STATUS_OK);
    }
}