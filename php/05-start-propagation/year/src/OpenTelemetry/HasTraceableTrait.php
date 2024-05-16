<?php declare(strict_types=1);

namespace App\OpenTelemetry;

use OpenTelemetry\API\Globals;
use OpenTelemetry\API\Trace\SpanContextInterface;
use OpenTelemetry\API\Trace\SpanInterface;
use OpenTelemetry\API\Trace\SpanKind;
use OpenTelemetry\SDK\Trace\Tracer;


trait HasTraceableTrait
{
    private function getTracer(string $name): Tracer
    {
        if (null === $name) {
            $name = $this::class;
        }
        $tracerProvider = Globals::tracerProvider();
        return $tracerProvider->getTracer($name);
    }
    private function createSpan(string $name = null, bool $root = false): SpanInterface
    {
        if (null === $name) {
            $name = $this::class;
        }
        $tracer = $this->getTracer('io.opentelemetry.contrib.php');
        $spanBuilder = $tracer->spanBuilder($name)
            ->setSpanKind(SpanKind::KIND_SERVER);

        if ($root === true) {
            $spanBuilder->setParent(false);
        }

        return $spanBuilder->startSpan();
    }

    function createSpanWithLink(string $name, SpanContextInterface $linkedSpanContext): SpanInterface
    {
        if (null === $name) {
            $name = $this::class;
        }
        $tracer = $this->getTracer('io.opentelemetry.contrib.php');
        return $tracer->spanBuilder($name)
            ->addLink($linkedSpanContext)
            ->startSpan();
    }
}