<?php
require 'vendor/autoload.php';

use OpenTelemetry\API\Trace\TracerProvider;
use OpenTelemetry\API\Trace\Span;
use OpenTelemetry\API\Trace\SpanContext;
use OpenTelemetry\API\Trace\SpanKind;
use OpenTelemetry\SDK\Trace\SpanProcessor\SimpleSpanProcessor;
use OpenTelemetry\SDK\Trace\TracerProvider as SdkTracerProvider;
use OpenTelemetry\SDK\Trace\Tracer;
use OpenTelemetry\Contrib\Zipkin\Exporter as ZipkinExporter;

// Configure Zipkin Exporter
$exporter = new ZipkinExporter('http://localhost:9411/api/v2/spans');

// Configure Tracer Provider
$tracerProvider = new SdkTracerProvider(
    new SimpleSpanProcessor($exporter)
);
TracerProvider::setDefault($tracerProvider);

// Get a tracer
$tracer = $tracerProvider->getTracer('io.opentelemetry.contrib.php');

// Start a span
$rootSpan = $tracer->spanBuilder('root-span')->startSpan();
$rootSpan->activate();

// Create a child span
$childSpan = $tracer->spanBuilder('child-span')->startSpan();
$childSpan->activate();

// Create another span to link to
$linkedSpan = $tracer->spanBuilder('linked-span')->startSpan();
$linkedSpanContext = $linkedSpan->getContext();

// Add a link to the linked span from the child span
$childSpan->addLink($linkedSpanContext);

// End the spans
$linkedSpan->end();
$childSpan->end();
$rootSpan->end();

// Shutdown the tracer provider to ensure all spans are exported
$tracerProvider->shutdown();

echo "Traces created and linked successfully.\n";
?>

