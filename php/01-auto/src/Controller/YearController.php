<?php

namespace App\Controller;

use App\OpenTelemetry\HasTraceableTrait;
use OpenTelemetry\API\Trace\SpanInterface;
use OpenTelemetry\API\Trace\SpanBuilderInterface;
use Opentelemetry\Proto\Trace\V1\Span_Event;
use OpenTelemetry\SDK\Trace\SpanBuilder;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;
use OpenTelemetry\SDK\Trace\Tracer;
use App\OpenTelemetry\SdkBuilder;
use OpenTelemetry\API\Globals;
use OpenTelemetry\Contrib\Otlp\OtlpHttpTransportFactory;

use OpenTelemetry\API\Trace\SpanKind;
use OpenTelemetry\API\Trace\StatusCode;
use OpenTelemetry\API\Trace\TraceInterface;
use OpenTelemetry\API\Trace\Span;

use OpenTelemetry\Context\ContextInterface;
use OpenTelemetry\SDK\Common\Time\ClockFactory;
use OpenTelemetry\Contrib\Otlp\SpanExporter;
use OpenTelemetry\SDK\Trace\SpanProcessor\BatchSpanProcessor;
use OpenTelemetry\SDK\Trace\TracerProvider;
use OpenTelemetry\API\Trace\Propagation\TraceContextPropagator;
use OpenTelemetry\SDK\Sdk;
use OpenTelemetry\API\Signals;
use OpenTelemetry\SDK\Common\Configuration\Configuration;
use OpenTelemetry\SDK\Common\Configuration\Variables;
use OpenTelemetry\SDK\Resource\ResourceInfo;
use OpenTelemetry\SemConv\ResourceAttributes;
use OpenTelemetry\SDK\Common\Attribute\Attributes;
use OpenTelemetry\Contrib\Otlp\OtlpUtil;


class YearController extends AbstractController
{

    use HasTraceableTrait;

    private SdkBuilder $builder;
    private Tracer $tracer;
    private string $jaegerGuiUrl;
    private string $zipkinGuiUrl;

    #[Route('/year', name: 'app_year')]
    public function getRandomYear(): Response
    {
        $builder = new SdkBuilder();
        $this->builder = $builder;


        $headers = [];
        $headers = OtlpUtil::getHeaders(Signals::TRACE);

        // If using collector, it probably works better with 'application/json'. For Honeycomb it only worked with 'application/x-protobuf'/ C
        $transport = (new OtlpHttpTransportFactory())->create(Configuration::getString(Variables::OTEL_EXPORTER_OTLP_ENDPOINT), 'application/x-protobuf', $headers);
        $exporter = new SpanExporter($transport);

        echo 'Starting OTLP+json example\n';

        $resource = ResourceInfo::create(Attributes::create([
            ResourceAttributes::SERVICE_NAMESPACE => 'Demo',
            ResourceAttributes::SERVICE_NAME => 'year-php',
        ]));

        $tracerProvider = new TracerProvider(
            spanProcessors: [new BatchSpanProcessor($exporter, ClockFactory::getDefault())],
            resource: $resource,
        );

        Sdk::builder()
            ->setTracerProvider($tracerProvider)
            ->setPropagator(TraceContextPropagator::getInstance())
            ->setAutoShutdown(true)
            ->buildAndRegisterGlobal();


        $root = $span = $tracer->spanBuilder('root')->startSpan();
        $scope = $span->activate();

        // simulate some computation
        usleep(50000);

        $currentYear = date("Y"); // Get the current year
        usleep(rand(0, 5000)); // Simulate a small delay
        $randomYear = rand(2015, $currentYear); // Get a random year between 2015 and current year

        return new Response((string) $randomYear, 200, ['Content-Type' => 'text/plain']);
        // return rendered HTML
    }


}