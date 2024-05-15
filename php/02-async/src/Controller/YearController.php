<?php

namespace App\Controller;

require __DIR__ . '/../../vendor/autoload.php';

use React\EventLoop\Factory as LoopFactory;
use React\Promise\Promise;
use App\OpenTelemetry\HasTraceableTrait;
use App\OpenTelemetry\SdkBuilder;
use OpenTelemetry\API\Signals;
use OpenTelemetry\API\Trace\Propagation\TraceContextPropagator;
use OpenTelemetry\API\Trace\SpanInterface;
use OpenTelemetry\Contrib\Otlp\OtlpHttpTransportFactory;
use OpenTelemetry\Contrib\Otlp\OtlpUtil;
use OpenTelemetry\Contrib\Otlp\SpanExporter;
use OpenTelemetry\SDK\Common\Attribute\Attributes;
use OpenTelemetry\SDK\Common\Configuration\Configuration;
use OpenTelemetry\SDK\Common\Configuration\Variables;
use OpenTelemetry\SDK\Common\Time\ClockFactory;
use OpenTelemetry\SDK\Resource\ResourceInfo;
use OpenTelemetry\SDK\Sdk;
use OpenTelemetry\SDK\Trace\SpanProcessor\BatchSpanProcessor;
use OpenTelemetry\SDK\Trace\TracerProvider;
use OpenTelemetry\SemConv\ResourceAttributes;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Attribute\Route;




class YearController extends AbstractController
{
    use HasTraceableTrait;


    private TracerProvider $tracerProvider;

    private ?SpanInterface $span, $root, $scope = null;

    #[Route('/year', name: 'app_year')]
    public function index(): JsonResponse
    {
        $loop = LoopFactory::create();
        $this->instrumentedNormalAsync($loop);
        $loop->run();
        $loop = LoopFactory::create();
        $this->instrumentedNormalAsync($loop);
        $loop->run();
        //$this->instrumentedNormal();
        //$this->instrumentEasier();
        return new JsonResponse("Go see your traces!");
    }
    function getRandomYear(): int
    {
        $currentYear = date("Y"); // Get the current year
        usleep(rand(0, 5000)); // Simulate a small delay
        $randomYear = rand(2015, $currentYear); // Get a random year between 2015 and current year
        return $randomYear;
    }

    // The Normal
    public function instrumentedNormal()
    {

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

        $tracer = $tracerProvider->getTracer('year-php');

        $root = $span = $tracer->spanBuilder('root')->startSpan();
        $scope = $span->activate();

        for ($i = 0; $i < 3; $i++) {
            // start a span, register some events, add span events
            $span = $tracer->spanBuilder('loop-' . $i)->startSpan();

            $span->setAttribute('year', $this->getRandomYear());
            ;
            $span->addEvent('event ' . $i, [
                'event_id' => $i,
                'username' => 'otuser' . $i,
            ]);
            $span->addEvent('generated_session', [
                'id' => md5((string) microtime(true)),
            ]);

            $span->end();
        }

        $span = $tracer->spanBuilder('Play with links')->setParent(false)->startSpan();

        // add more tuff
        $spanContext = $span->getContext();
        $span->end();

        // Associate it back
        $span = $tracer->spanBuilder('span-with-link')
            ->addLink($spanContext)
            ->startSpan();

        $span->end();
        $root->end();
        $scope->detach();
        echo PHP_EOL . 'OTLP example complete!  ';

        echo PHP_EOL;
        $tracerProvider->shutdown();
        return;
    }

    function instrumentEasier()
    {
        // Setup tracers, exporters, connection
        $this->builder = new SdkBuilder();
        $this->builder->build();

        // Create root span
        $root = $this->createSpan('root-easier');

        // Active it
        $scope = $root->activate();
        for ($i = 0; $i < 3; $i++) {
            // start a span, register some events, add span events
            $span = $this->createSpan('loop-' . $i);

            // Add custom attributes
            $span->setAttribute('year', $this->getRandomYear());

            // Add span events
            $span->addEvent('event ' . $i, [
                'event_id' => $i,
                'username' => 'otuser' . $i,
            ]);

            $span->addEvent('generated_session', [
                'id' => md5((string) microtime(true)),
            ]);

            $span->end();
        }

        $span = $this->createSpan('Play with links', true);

        // add more tuff
        $spanContext = $span->getContext();
        $span->end();

        // Associate it back
        $span = $this->createSpanWithLink('span-with-link', $spanContext);
        $span->end();
        $scope->detach();
        $root->end();
        return;
    }


    public function instrumentedNormalAsync($loop)
    {
        $headers = OtlpUtil::getHeaders(\OpenTelemetry\API\Signals::TRACE);
        $transport = (new OtlpHttpTransportFactory())->create(Configuration::getString(Variables::OTEL_EXPORTER_OTLP_ENDPOINT), 'application/x-protobuf', $headers);
        $exporter = new SpanExporter($transport);

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

        $tracer = $tracerProvider->getTracer('year-php');
        $root = $tracer->spanBuilder('root')->startSpan();
        $scope = $root->activate();

        for ($i = 0; $i < 3; $i++) {
            $this->createSpanAsync($loop, $tracer, 'loop-' . $i);
        }

        $loop->addTimer(1.0, function () use ($root, $scope, $tracerProvider) {
            $root->end();
            $scope->detach();
            $tracerProvider->shutdown();
        });
    }

    private function createSpanAsync($loop, $tracer, $name)
    {
        $loop->addTimer(0.0001, function () use ($tracer, $name) {
            $span = $tracer->spanBuilder($name)->startSpan();
            $span->setAttribute('year', $this->getRandomYear());
            $span->addEvent('some event', ['attributes' => ['key' => 'value']]);
            $span->end();
        });
    }


}

